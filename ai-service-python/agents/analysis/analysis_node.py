from state import AgentState
from agents.analysis.analysis_service import evaluate_candidates_skills

def analysis_node(state: AgentState) -> dict:
    """
    The Analysis Agent node for LangGraph.
    Acts as the controller: parses state, calls the service to perform Tier 2 
    Semantic Skill Matching, and updates state with passing candidates.
    """
    print("Analysis Agent (Agent 2) running...")
    candidates = state.get("candidates", [])
    job = state.get("job_posting", {})
    
    if not candidates:
        print("No candidates provided to Analysis Agent.")
        return {"analysis_results": []}
        
    final_results = evaluate_candidates_skills(candidates, job)
    
    print(f"✅ Analysis Agent (Agent 2) finished! {len(final_results)} out of {len(candidates)} candidates passed the 60% threshold.")
    
    return {
        "analysis_results": final_results
    }
