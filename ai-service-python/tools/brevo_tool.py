"""Brevo adapter used by the orchestration service."""

from __future__ import annotations

import os
import requests

def send_email(to_email: str, subject: str, plain_text: str) -> bool:
    api_key = os.getenv("BREVO_API_KEY")
    if not api_key:
        print("Warning: BREVO_API_KEY is not configured. Email mocked as sent.")
        return True
    
    from_email = os.getenv("BREVO_SENDER_EMAIL", "noreply@campusai.local")
    from_name = os.getenv("BREVO_SENDER_NAME", "CampusAI")
    
    payload = {
        "sender": {"email": from_email, "name": from_name},
        "to": [{"email": to_email, "name": to_email.split('@')[0]}],
        "subject": subject,
        "textContent": plain_text
    }
    
    headers = {
        "api-key": api_key,
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post("https://api.brevo.com/v3/smtp/email", json=payload, headers=headers)
        if 200 <= response.status_code < 300:
            return True
        else:
            print(f"Brevo API error: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"Failed to send email to {to_email}: {e}")
        return False
