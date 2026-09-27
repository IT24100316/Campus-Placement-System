import asyncio
from state import AgentState
from agents.planner.planner_service import generate_evaluation_rubric, preparse_candidate_cvs

async def planner_node(state: AgentState) -> dict:
    """
    Planner Node (Agent 1):
    Acts as the 'Head Chef'. It analyzes the job posting to generate an intelligent
    evaluation rubric for Agent 3. It also orchestrates data preparation by downloading
    and parsing CVs for all candidates concurrently.
    """
    print("Planner Agent (Agent 1) running...")
    
    job_posting = state.get("job_posting", {})
    candidates = state.get("candidates", [])
    
    rubric = await generate_evaluation_rubric(job_posting)
    
    print(f"✅ Planner Agent (Agent 1) finished! Generated Rubric.")
    
    return {
        "evaluation_rubric": rubric,
        "candidates": candidates
    }
