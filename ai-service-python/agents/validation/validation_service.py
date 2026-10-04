import base64
import io
import json
import re
import difflib
from dataclasses import asdict
from typing import Any
import requests
from pypdf import PdfReader
from agents.validation.validation_models import ValidationResult

STOP_WORDS = {
    "about", "after", "also", "and", "are", "because", "been", "before", "being",
    "candidate", "for", "from", "has", "have", "into", "its", "that", "the", "their",
    "this", "was", "were", "with", "years", "student", "summary", "skills",
    "excellent", "strong", "proficient", "developed", "demonstrated", "experienced", 
    "knowledge", "working", "understanding", "good", "advanced", "basic", "familiar", 
    "using", "used", "built", "created", "designed", "implemented", "managed", "led", 
    "team", "project", "work", "experience", "highly", "skilled", "various", "multiple",
    "technologies", "tools", "frameworks", "languages", "environments", "applications"
}

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

    supported = []
    unsupported = []
    cv_terms_list = list(cv_terms)
    
    for term in summary_terms:
        if term in cv_terms:
            supported.append(term)
        else:
            matches = difflib.get_close_matches(term, cv_terms_list, n=1, cutoff=0.8)
            if matches:
                supported.append(term)
            else:
                unsupported.append(term)

    supported = sorted(supported)
    unsupported = sorted(unsupported)
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
