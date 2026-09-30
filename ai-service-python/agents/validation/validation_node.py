import json
import os
import requests
from agents.validation.validation_service import run_validation

def validation_node(state: dict) -> dict:
    """
    Agent 4: Validation & Webhook.
    Takes the summary, runs validation against the CV, and fires a webhook to .NET
    to notify that the student is Ready for Review, then the graph will pause.
    """
    analysis_results = state.get("analysis_results", [])
    candidates = state.get("candidates", [])
    
    for result in analysis_results:
        student_id = result.get("student_id")
        summary = result.get("summary")
        student_data = next((c for c in candidates if str(c.get("UserId")) == str(student_id)), {})
        cv_url = student_data.get("CvPdfUrl", "")
        if cv_url and not cv_url.startswith("http"):
            cv_url = f"https://hyxtmbncjolcepfvongh.supabase.co/storage/v1/object/public/student-cvs/{cv_url}"
        
        # 1. Run deterministic validation
        try:
            print(f"Agent 4 validating {student_id}...")
            val_result = run_validation(summary, cv_pdf_url=cv_url)
            result["validation"] = val_result
        except Exception as e:
            print(f"Agent 4 error on {student_id}: {e}")
            result["validation"] = {"error": str(e)}
            
        job_id = state.get("job_id")
        
        # 2. Fire the Iterative Webhook to .NET
        from tools.webhook_tool import send_validation_webhook
        send_validation_webhook(student_id, job_id, result.get("match_score", 0), result)
                
    print(f"✅ Validation Agent (Agent 4) finished! Fired {len(analysis_results)} webhooks.")
    return {"analysis_results": analysis_results}
