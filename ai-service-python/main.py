from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import HTTPException
from pydantic import BaseModel, Field, model_validator
from typing import Any
import requests
from agents.validation import run_validation
from tools.sendgrid_tool import send_email

app = FastAPI(
    title="Campus Placement AI Orchestration Service",
    version="1.0.0"
)

# Allow backend ASP.NET service to call this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
