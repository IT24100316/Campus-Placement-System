import os
import asyncio
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from dotenv import load_dotenv

from agents.action import evaluate_single_candidate
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Any
from langgraph.graph import StateGraph, START, END

from state import AgentState
from agents.tier1_filter import tier1_node
from agents.analysis import analysis_node
from fastapi import HTTPException
from pydantic import BaseModel, Field, model_validator
from typing import Any
import requests
from agents.validation import run_validation
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

class BatchEvaluationRequest(BaseModel):
    job_data: Dict[str, Any]
    candidates: List[CandidatePayload]

@app.post("/api/v1/evaluate-batch")
async def evaluate_batch(request: BatchEvaluationRequest):
    job_data = request.job_data
    candidates = request.candidates
    
    # Process a single candidate and return the result mapping
    async def process_candidate(candidate):
        eval_result = await evaluate_single_candidate(candidate.student_data, job_data, candidate.cv_url)
        return {
            "application_id": candidate.application_id,
            "evaluation": eval_result
        }
    
    # Process all candidates concurrently using asyncio.gather
    tasks = [process_candidate(candidate) for candidate in candidates]
    
    try:
        results = await asyncio.gather(*tasks)
        return {"evaluations": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
# ==========================================
# MOCK NODES (For Teammates)
# ==========================================
def planner_node(state: AgentState) -> dict:
    """Mock node for the Planner Agent. Teammate to implement."""
    print("Planner Agent running...")
    return {}

def action_node(state: AgentState) -> dict:
    """Mock node for the Action Agent. Teammate to implement."""
    print("Action Agent running...")
    return {}

def validation_node(state: AgentState) -> dict:
    """Mock node for the Validation Agent. Teammate to implement."""
    print("Validation Agent running...")
    return {}

# ==========================================
# ORCHESTRATION GRAPH
# ==========================================
workflow = StateGraph(AgentState)

# Add Nodes
workflow.add_node("planner", planner_node)
workflow.add_node("action", action_node)
workflow.add_node("tier1", tier1_node)
workflow.add_node("analysis", analysis_node)
workflow.add_node("validation", validation_node)

# Define Edges
workflow.add_edge(START, "tier1")
workflow.add_edge("tier1", "planner")
workflow.add_edge("planner", "action")
workflow.add_edge("action", "analysis")
workflow.add_edge("analysis", "validation")
workflow.add_edge("validation", END)

# Compile Graph
app_graph = workflow.compile()

# ==========================================
# API ENDPOINTS
# ==========================================
class AnalyzeRequest(BaseModel):
    job_id: str
    student_ids: List[str]

@app.post("/analyze")
def run_orchestration(request: AnalyzeRequest):
    """
    Trigger the entire AI multi-agent orchestration workflow.
    """
    initial_state = {
        "job_id": request.job_id,
        "initial_student_ids": request.student_ids
    }
    
    # Invoke the LangGraph
    final_state = app_graph.invoke(initial_state)
    
    # Return the analysis results for the frontend/backend to consume
    return {
        "status": "success",
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


@app.post("/validate")
def validate_application(request: ValidationRequest):
    try:
        result = run_validation(
            request.summary,
            cv_pdf_url=request.cv_pdf_url,
            cv_pdf_base64=request.cv_pdf_base64,
        )
        return {"application_id": request.application_id, **result}
    except (ValueError, requests.RequestException) as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@app.post("/notifications/email")
def email_notification(request: EmailRequest):
    try:
        return {"sent": send_email(request.to_email, request.subject, request.message)}
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail="SendGrid delivery failed.") from exc
