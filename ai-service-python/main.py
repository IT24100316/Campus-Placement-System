from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Any
from langgraph.graph import StateGraph, START, END

from state import AgentState
from agents.tier1_filter import tier1_node
from agents.analysis import analysis_node

app = FastAPI(
    title="Campus Placement AI Orchestration Service",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
workflow.add_edge(START, "planner")
workflow.add_edge("planner", "action")
workflow.add_edge("action", "tier1")
workflow.add_edge("tier1", "analysis")
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