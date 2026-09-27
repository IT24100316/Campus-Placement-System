from state import AgentState
from agents.action.action_service import evaluate_single_candidate

async def action_node(state: AgentState) -> dict:
    """
    Agent 3: Summary Writer. 
    Takes passing candidates from Analysis and writes the AdminEvaluationSummary using Gemini.
    """
    job_posting = state.get("job_posting", {})
    rubric = state.get("evaluation_rubric", "")
    candidates = state.get("candidates", [])
    analysis_results = state.get("analysis_results", [])
    
    # We will enrich the analysis_results with the summary
    enriched_results = []
    
    # Iterate through candidates who passed Analysis (they have a match_score)
    for result in analysis_results:
        student_id = result.get("student_id")
        student_data = next((c for c in candidates if str(c.get("UserId")) == str(student_id)), {})
        
        cv_url = student_data.get("CvPdfUrl", "")
        cv_text = student_data.get("cv_text")
        
        try:
            print(f"Agent 3 generating summary for {student_id} ({student_data.get('FullName', 'Unknown')})...")
            summary = await evaluate_single_candidate(student_data, job_posting, cv_url, cv_text, rubric)
            result["summary"] = summary
            print(f"[{student_data.get('FullName', 'Unknown')}] Successfully processed.")
        except Exception as e:
            print(f"Error generating summary for {student_id}: {e}")
            result["summary"] = {"error": str(e)}
            
        enriched_results.append(result)
        
    print(f"✅ Action Agent (Agent 3) finished! Generated {len(enriched_results)} summaries.")
    return {"analysis_results": enriched_results}
