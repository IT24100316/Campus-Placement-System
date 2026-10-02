import os
import requests

def send_validation_webhook(student_id: str, job_id: str, match_score: int, result: dict) -> bool:
    """
    Fires a webhook to the .NET backend with the validation evaluation results.
    """
    webhook_url = os.getenv("DOTNET_WEBHOOK_URL")
    webhook_secret = os.getenv("WEBHOOK_SECRET")
    
    if not webhook_url:
        print("Warning: DOTNET_WEBHOOK_URL not configured. Webhook skipped.")
        return False
        
    payload = {
        # The backend resolves the existing application using JobId + StudentId.
        # A student ID is never an application ID.
        "ApplicationId": "00000000-0000-0000-0000-000000000000",
        "JobId": job_id,
        "StudentId": student_id,
        "IsSuccess": not bool(result.get("validation", {}).get("error")),
        "MatchScore": match_score,
        "ResultJson": __import__('json').dumps(result)
    }
    
    try:
        resp = requests.post(
            webhook_url,
            json=payload,
            headers={"x-webhook-secret": webhook_secret or ""},
            timeout=10
        )
        print(f"Webhook fired for {student_id}, status: {resp.status_code}")
        return resp.status_code == 200
    except Exception as e:
        print(f"Failed to call webhook for {student_id}: {e}")
        return False
