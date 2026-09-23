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
