"""Small SendGrid adapter used by the orchestration service."""

from __future__ import annotations

import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail


def send_email(to_email: str, subject: str, plain_text: str) -> bool:
    api_key = os.getenv("SENDGRID_API_KEY")
    if not api_key:
        raise RuntimeError("SENDGRID_API_KEY is not configured.")
    message = Mail(
        from_email=os.getenv("SENDGRID_FROM_EMAIL", "noreply@example.edu"),
        to_emails=to_email,
        subject=subject,
        plain_text_content=plain_text,
    )
    response = SendGridAPIClient(api_key).send(message)
    return 200 <= response.status_code < 300
