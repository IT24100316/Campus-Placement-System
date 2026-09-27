"""Agent 4: deterministic CV-grounding validation before human approval."""

from __future__ import annotations

import base64
import io
import json
import re
from dataclasses import asdict, dataclass
from typing import Any

import requests
from pypdf import PdfReader


STOP_WORDS = {
    "about", "after", "also", "and", "are", "because", "been", "before", "being",
    "candidate", "for", "from", "has", "have", "into", "its", "that", "the", "their",
    "this", "was", "were", "with", "years", "student", "summary", "skills",
}


@dataclass(frozen=True)
class ValidationResult:
    valid: bool
    confidence: float
    supported_terms: list[str]
    unsupported_terms: list[str]
    warnings: list[str]
    decision: str = "WAITING_FOR_ADMIN_APPROVAL"


def extract_pdf_text(pdf_bytes: bytes) -> str:
    if not pdf_bytes.startswith(b"%PDF"):
        raise ValueError("CV payload is not a PDF document.")
    reader = PdfReader(io.BytesIO(pdf_bytes))
    text = "\n".join(page.extract_text() or "" for page in reader.pages).strip()
    if not text:
        raise ValueError("No readable text was found in the CV PDF.")
    return text


def load_pdf(*, url: str | None = None, encoded: str | None = None) -> bytes:
    if encoded:
        try:
            return base64.b64decode(encoded, validate=True)
        except ValueError as exc:
            raise ValueError("cv_pdf_base64 is invalid.") from exc
    if not url or not url.lower().startswith(("http://", "https://")):
        raise ValueError("Provide an HTTP(S) CV URL or base64-encoded PDF.")
    response = requests.get(url, timeout=15, allow_redirects=True)
    response.raise_for_status()
    if len(response.content) > 10 * 1024 * 1024:
        raise ValueError("CV PDF exceeds the 10 MB validation limit.")
    return response.content


def _flatten_summary(summary: Any) -> str:
    if isinstance(summary, str):
        try:
            parsed = json.loads(summary)
            if isinstance(parsed, (dict, list)):
                return _flatten_summary(parsed)
        except json.JSONDecodeError:
            pass
        return summary
    if isinstance(summary, dict):
        return " ".join(f"{key} {_flatten_summary(value)}" for key, value in summary.items())
    if isinstance(summary, list):
        return " ".join(_flatten_summary(value) for value in summary)
    return str(summary)


def _terms(text: str) -> set[str]:
    return {
        token for token in re.findall(r"[a-zA-Z][a-zA-Z0-9+#.\-]{2,}", text.lower())
        if token not in STOP_WORDS
    }


def validate_summary_against_cv(summary: Any, cv_text: str) -> ValidationResult:
    summary_terms = _terms(_flatten_summary(summary))
    cv_terms = _terms(cv_text)
    if not summary_terms:
        return ValidationResult(False, 0.0, [], [], ["Summary contains no verifiable terms."])

    supported = sorted(summary_terms & cv_terms)
    unsupported = sorted(summary_terms - cv_terms)
    confidence = round(len(supported) / len(summary_terms), 3)
    warnings = []
    if unsupported:
        warnings.append("Some summary terms were not found in the CV and require administrator review.")
    if confidence < 0.55:
        warnings.append("Low evidence overlap: do not approve automatically.")
    return ValidationResult(confidence >= 0.55, confidence, supported, unsupported, warnings)


def run_validation(summary: Any, *, cv_pdf_url: str | None = None, cv_pdf_base64: str | None = None) -> dict[str, Any]:
    pdf_text = extract_pdf_text(load_pdf(url=cv_pdf_url, encoded=cv_pdf_base64))
    return asdict(validate_summary_against_cv(summary, pdf_text))

def validation_node(state: dict) -> dict:
    """
    Agent 4: Validation & Webhook.
    Takes the summary, runs validation against the CV, and fires a webhook to .NET
    to notify that the student is Ready for Review, then the graph will pause.
    """
    analysis_results = state.get("analysis_results", [])
    candidates = state.get("candidates", [])
    
    import os
    webhook_url = os.getenv("DOTNET_WEBHOOK_URL")
    webhook_secret = os.getenv("WEBHOOK_SECRET")
    
    for result in analysis_results:
        student_id = result.get("student_id")
        summary = result.get("summary")
        student_data = next((c for c in candidates if str(c.get("UserId")) == str(student_id)), {})
        cv_url = student_data.get("CvPdfUrl", "")
        
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
        payload = {
            "ApplicationId": student_id, # Can be null or match student id, backend handles it
            "JobId": job_id,
            "StudentId": student_id,
            "IsSuccess": True,
            "ResultJson": json.dumps(result)
        }
        
        if webhook_url:
            try:
                # We use synchronous requests here because validation_node is sync. 
                # (We could make it async if needed)
                resp = requests.post(
                    webhook_url,
                    json=payload,
                    headers={"x-webhook-secret": webhook_secret or ""},
                    timeout=10
                )
                print(f"Webhook fired for {student_id}, status: {resp.status_code}")
            except Exception as e:
                print(f"Failed to call webhook for {student_id}: {e}")
                
    return {"analysis_results": analysis_results}

