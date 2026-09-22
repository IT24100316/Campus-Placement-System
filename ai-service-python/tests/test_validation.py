from agents.validation import validate_summary_against_cv


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
