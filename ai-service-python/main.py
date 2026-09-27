import os
import asyncio
import uuid
import json
import requests
import httpx
from typing import List, Dict, Any

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, model_validator
from dotenv import load_dotenv

from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

from state import AgentState
from agents.planner import planner_node
from agents.tier1 import tier1_node
from agents.analysis import analysis_node
from agents.action import action_node
from agents.validation import validation_node, run_validation
from tools.sendgrid_tool import send_email

# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app
app = FastAPI(title="Agent 3 - Evaluation Engine", version="1.0")

# Add CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define Pydantic request models
class CandidatePayload(BaseModel):
    application_id: str
    student_data: Dict[str, Any]
    cv_url: str


def email_node(state: dict) -> dict:
    """
    Agent 5: Email Notification.
    This node runs ONLY after the graph resumes from its HITL pause.
    It checks human_approved and sends the final verdict email.
    """
    human_approved = state.get("human_approved")
    candidates = state.get("candidates", [])
    analysis_results = state.get("analysis_results", [])
    
    if human_approved is None:
        print("No human approval recorded, skipping email.")
        return {}
        
    for result in analysis_results:
        student_id = result.get("student_id")
        student_data = next((c for c in candidates if str(c.get("UserId")) == str(student_id)), {})
        email = student_data.get("Email")
        
        if email:
            if human_approved:
                subject = "AI Match: You have been selected!"
                message = f"Hello,\n\nCongratulations! Our AI Matchmaker identified you as a top candidate for a new job opportunity. The university Admin has verified your profile. Log in to your portal to accept this opportunity!\n\nBest,\nCampus AI Team"
            else:
                subject = "Update on your AI Match"
                message = f"Hello,\n\nOur AI initially matched you for a new role, but after administrator review, we decided it wasn't the perfect fit at this time. Keep your profile updated for future matches!\n\nBest,\nCampus AI Team"
                
            try:
                print(f"Sending email to {email}...")
                send_email(email, subject, message)
            except Exception as e:
                print(f"Failed to send email to {email}: {e}")
                
    return {}

# ==========================================
# ORCHESTRATION GRAPH
# ==========================================
workflow = StateGraph(AgentState)

# Add Nodes
workflow.add_node("planner", planner_node)
workflow.add_node("tier1", tier1_node)
workflow.add_node("analysis", analysis_node)
workflow.add_node("action", action_node)
workflow.add_node("validation", validation_node)
workflow.add_node("email", email_node)

# Define Edges (Planner -> Tier 1 -> Analysis -> Action -> Validation -> Email)
workflow.add_edge(START, "planner")
workflow.add_edge("planner", "tier1")
workflow.add_edge("tier1", "analysis")
workflow.add_edge("analysis", "action")
workflow.add_edge("action", "validation")
workflow.add_edge("validation", "email")
workflow.add_edge("email", END)


memory = MemorySaver()

# Compile Graph with HITL Pause
app_graph = workflow.compile(
    checkpointer=memory,
    interrupt_after=["validation"]
)

# ==========================================
# API ENDPOINTS
# ==========================================
class AnalyzeRequest(BaseModel):
    job_id: str
    student_ids: List[str] = []
    evaluate_all: bool = False

@app.post("/analyze")
async def run_orchestration(request: AnalyzeRequest):
    """
    Trigger the entire AI multi-agent orchestration workflow.
    """
    thread_id = str(uuid.uuid4())
    config = {"configurable": {"thread_id": thread_id}}
    
    initial_state = {
        "job_id": request.job_id,
        "initial_student_ids": request.student_ids,
        "evaluate_all": request.evaluate_all
    }
    
    # Invoke the LangGraph (it will run until 'validation' node and pause)
    final_state = await app_graph.ainvoke(initial_state, config=config)
    
    # We return the thread_id so the backend can resume it later
    try:
        with open("scratch/output.json", "w") as f:
            f.write(json.dumps(final_state, default=str))
    except Exception as e:
        print("Could not dump final state:", e)

    return {
        "status": "paused_for_human_review",
        "thread_id": thread_id,
        "results": final_state.get("analysis_results", [])
    }

class ResumeRequest(BaseModel):
    thread_id: str
    human_approved: bool

@app.post("/resume")
async def resume_orchestration(request: ResumeRequest):
    """
    Resume the sleeping LangGraph after Human Admin approves/rejects.
    """
    config = {"configurable": {"thread_id": request.thread_id}}
    
    # Update the graph state with human's decision
    await app_graph.aupdate_state(config, {"human_approved": request.human_approved})
    
    # Resume the graph from where it paused (validation node)
    final_state = await app_graph.ainvoke(None, config=config)
    
    return {
        "status": "completed",
        "human_approved": request.human_approved,
        "results": final_state.get("analysis_results", [])
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "ai-service-python"}


class ValidationRequest(BaseModel):
    application_id: str
    summary: Any
    cv_pdf_url: str | None = None
    cv_pdf_base64: str | None = None

    @model_validator(mode="after")
    def has_cv(self):
        if not self.cv_pdf_url and not self.cv_pdf_base64:
            raise ValueError("A CV URL or base64 PDF is required.")
        return self


class EmailRequest(BaseModel):
    to_email: str
    subject: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=10_000)


def process_validation_background(request: ValidationRequest):
    webhook_url = os.getenv("DOTNET_WEBHOOK_URL")
    webhook_secret = os.getenv("WEBHOOK_SECRET")
    
    payload = {
        "ApplicationId": request.application_id,
        "IsSuccess": False,
        "ResultJson": None
    }
    
    try:
        result = run_validation(
            request.summary,
            cv_pdf_url=request.cv_pdf_url,
            cv_pdf_base64=request.cv_pdf_base64,
        )
        payload["IsSuccess"] = True
        payload["ResultJson"] = json.dumps(result)
    except Exception as e:
        payload["IsSuccess"] = False
        payload["ResultJson"] = json.dumps({"error": str(e)})
        
    if webhook_url:
        try:
            with httpx.Client() as client:
                client.post(
                    webhook_url,
                    json=payload,
                    headers={"x-webhook-secret": webhook_secret or ""}
                )
        except Exception as e:
            print(f"Failed to call webhook: {e}")

@app.post("/validate")
def validate_application(request: ValidationRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(process_validation_background, request)
    return JSONResponse(status_code=202, content={"message": "Evaluation started in background"})


@app.post("/notifications/email")
def email_notification(request: EmailRequest):
    try:
        return {"sent": send_email(request.to_email, request.subject, request.message)}
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail="SendGrid delivery failed.") from exc
