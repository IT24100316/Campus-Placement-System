import base64
import io

import pytest
from pypdf import PdfWriter

from agents.validation import validate_summary_against_cv
from agents.validation.validation_service import extract_pdf_text, load_pdf
from tools.webhook_tool import send_validation_webhook


def test_validation_accepts_cv_grounded_summary():
    result = validate_summary_against_cv(
        {"skills": ["Python", "PostgreSQL"], "experience": "data analytics internship"},
        "Data analytics internship using Python and PostgreSQL for reporting.",
    )
    assert result.valid is True
    assert result.confidence >= 0.55
    assert "python" in result.supported_terms
    assert result.decision == "WAITING_FOR_ADMIN_APPROVAL"


def test_validation_flags_unsupported_claims():
    result = validate_summary_against_cv(
        "Kubernetes architect with Rust and aerospace experience",
        "Student developer using JavaScript for a university website.",
    )
    assert result.valid is False
    assert "kubernetes" in result.unsupported_terms
    assert result.warnings


def test_validation_reports_invented_skill_among_supported_skills():
    result = validate_summary_against_cv(
        {"skills": ["Python", "PostgreSQL", "Kubernetes"]},
        "Built Python and PostgreSQL reporting tools.",
    )
    assert "kubernetes" in result.unsupported_terms
    assert "python" in result.supported_terms
    assert result.warnings
    assert result.valid is False
    assert result.unsupported_claims == ["kubernetes"]
    assert "Python" in result.evidence["python"]


def test_validation_flags_invented_gpa_even_with_supported_skill():
    result = validate_summary_against_cv(
        "Python developer with GPA 3.95",
        "Python developer. GPA 3.50.",
    )
    assert result.valid is False
    assert "GPA 3.95" in result.unsupported_claims


def test_validation_rejects_summary_without_verifiable_terms():
    result = validate_summary_against_cv("Experienced student with strong skills", "Python")
    assert result.valid is False
    assert result.confidence == 0
    assert result.warnings


def test_validation_accepts_json_summary():
    result = validate_summary_against_cv('{"skills": ["Python"]}', "Python developer")
    assert "python" in result.supported_terms


@pytest.mark.parametrize("payload", [b"not a PDF", b""])
def test_extract_pdf_text_rejects_non_pdf(payload):
    with pytest.raises(ValueError, match="not a PDF"):
        extract_pdf_text(payload)


def test_extract_pdf_text_rejects_pdf_without_readable_text():
    writer = PdfWriter()
    writer.add_blank_page(width=200, height=200)
    output = io.BytesIO()
    writer.write(output)
    with pytest.raises(ValueError, match="No readable text"):
        extract_pdf_text(output.getvalue())


def test_load_pdf_rejects_invalid_base64():
    with pytest.raises(ValueError, match="invalid"):
        load_pdf(encoded="not valid base64!")


def test_load_pdf_limits_base64_payload_size():
    payload = base64.b64encode(b"x" * (10 * 1024 * 1024 + 1)).decode()
    with pytest.raises(ValueError, match="10 MB"):
        load_pdf(encoded=payload)


def test_load_pdf_rejects_non_http_url():
    with pytest.raises(ValueError, match="HTTP\\(S\\)"):
        load_pdf(url="file:///tmp/private.pdf")


def test_private_cv_download_uses_service_key_not_public_url(monkeypatch):
    requests_seen = []

    class Response:
        content = b"%PDF-private"

        def raise_for_status(self):
            pass

    def fake_get(url, **kwargs):
        requests_seen.append((url, kwargs))
        return Response()

    monkeypatch.setenv("SUPABASE_URL", "https://storage.example.edu")
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "test-private-key")
    monkeypatch.setattr("agents.validation.validation_service.requests.get", fake_get)
    assert load_pdf(url="supabase://student-cvs/student/cv.pdf") == b"%PDF-private"
    assert "/object/student-cvs/student/cv.pdf" in requests_seen[0][0]
    assert "/public/" not in requests_seen[0][0]
    assert requests_seen[0][1]["headers"]["Authorization"] == "Bearer test-private-key"


def test_load_pdf_limits_downloaded_payload(monkeypatch):
    class Response:
        content = b"x" * (10 * 1024 * 1024 + 1)

        def raise_for_status(self):
            pass

    monkeypatch.setattr("agents.validation.validation_service.requests.get", lambda *args, **kwargs: Response())
    with pytest.raises(ValueError, match="10 MB"):
        load_pdf(url="https://example.com/cv.pdf")


@pytest.mark.parametrize("validation,expected_success", [
    ({"error": "Unreadable CV"}, False),
    ({"valid": False, "unsupported_terms": ["kubernetes"]}, True),
])
def test_webhook_distinguishes_validation_error_from_completed_review(
    monkeypatch, validation, expected_success
):
    captured = {}

    class Response:
        status_code = 200

    def fake_post(url, *, json, headers, timeout):
        captured.update(json)
        return Response()

    monkeypatch.setenv("DOTNET_WEBHOOK_URL", "https://example.com/webhook")
    monkeypatch.setattr("tools.webhook_tool.requests.post", fake_post)
    assert send_validation_webhook("student-id", "job-id", 75, {"validation": validation})
    assert captured["IsSuccess"] is expected_success
