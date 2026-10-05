"""Contract tests for each agent boundary, with external services mocked."""

import asyncio
import importlib
from unittest.mock import Mock

from agents.tier1 import tier1_node
from agents.planner import planner_node
from agents.analysis import analysis_node
from agents.action import action_node
from agents.validation import validation_node
from agents.planner.planner_service import preparse_candidate_cvs

tier1_module = importlib.import_module("agents.tier1.tier1_node")
planner_module = importlib.import_module("agents.planner.planner_node")
analysis_module = importlib.import_module("agents.analysis.analysis_node")
action_module = importlib.import_module("agents.action.action_node")
validation_module = importlib.import_module("agents.validation.validation_node")
planner_service_module = importlib.import_module("agents.planner.planner_service")


def test_tier1_requires_job_and_candidate_scope(monkeypatch):
    called = Mock()
    monkeypatch.setattr(tier1_module, "fetch_job_posting", called)
    assert tier1_node({"initial_student_ids": ["s1"]}) == {"candidates": [], "job_posting": {}}
    assert tier1_node({"job_id": "j1"}) == {"candidates": [], "job_posting": {}}
    called.assert_not_called()


def test_tier1_forwards_only_candidates_passing_hard_filters(monkeypatch):
    monkeypatch.setattr(tier1_module, "fetch_job_posting", lambda _: {"JobTitle": "Intern"})
    monkeypatch.setattr(tier1_module, "fetch_student_profile", lambda sid: {"UserId": sid})
    monkeypatch.setattr(
        tier1_module, "check_hard_filters_tool",
        Mock(invoke=lambda args: {"passed": args["student_id"] == "s1"}),
    )
    result = tier1_node({"job_id": "j1", "initial_student_ids": ["s1", "s2"]})
    assert result["job_posting"]["JobTitle"] == "Intern"
    assert result["candidates"] == [{"UserId": "s1"}]


def test_tier1_evaluate_all_uses_student_directory(monkeypatch):
    monkeypatch.setattr(tier1_module, "fetch_job_posting", lambda _: {"JobTitle": "Intern"})
    monkeypatch.setattr(tier1_module, "fetch_all_student_ids", lambda: ["s1"])
    monkeypatch.setattr(tier1_module, "fetch_student_profile", lambda sid: {"UserId": sid})
    monkeypatch.setattr(tier1_module, "check_hard_filters_tool", Mock(invoke=lambda _: {"passed": True}))
    result = tier1_node({"job_id": "j1", "evaluate_all": True})
    assert result["candidates"] == [{"UserId": "s1"}]


def test_planner_returns_generated_rubric_and_candidates(monkeypatch):
    async def fake_rubric(job):
        assert job == {"JobTitle": "Intern"}
        return "Check Python experience"

    monkeypatch.setattr(planner_module, "generate_evaluation_rubric", fake_rubric)
    candidates = [{"UserId": "s1"}]
    result = asyncio.run(planner_node({"job_posting": {"JobTitle": "Intern"}, "candidates": candidates}))
    assert result == {"evaluation_rubric": "Check Python experience", "candidates": candidates}


def test_planner_preparse_keeps_candidates_when_cv_extraction_fails(monkeypatch):
    async def fake_extract(url):
        if url.endswith("bad.pdf"):
            raise ValueError("unreadable")
        return "Python project"

    monkeypatch.setattr(planner_service_module, "extract_cv_text_locally", fake_extract)
    candidates = [
        {"UserId": "s1", "CvPdfUrl": "https://example.com/good.pdf"},
        {"UserId": "s2", "CvPdfUrl": "https://example.com/bad.pdf"},
        {"UserId": "s3"},
    ]
    result = asyncio.run(preparse_candidate_cvs(candidates))
    assert [candidate["cv_text"] for candidate in result] == ["Python project", "", ""]


def test_analysis_skips_evaluation_when_no_candidates(monkeypatch):
    called = Mock()
    monkeypatch.setattr(analysis_module, "evaluate_candidates_skills", called)
    assert analysis_node({"candidates": []}) == {"analysis_results": []}
    called.assert_not_called()


def test_action_preserves_score_and_attaches_summary(monkeypatch):
    async def fake_evaluate(student, job, cv_url, cv_text, rubric):
        assert (student["UserId"], cv_text, rubric) == ("s1", "CV text", "Check skills")
        return {"strengths": ["Python"]}

    monkeypatch.setattr(action_module, "evaluate_single_candidate", fake_evaluate)
    result = asyncio.run(action_node({
        "job_posting": {"JobTitle": "Intern"},
        "evaluation_rubric": "Check skills",
        "candidates": [{"UserId": "s1", "cv_text": "CV text", "CvPdfUrl": "https://example.com/cv.pdf"}],
        "analysis_results": [{"student_id": "s1", "match_score": 80}],
    }))
    assert result["analysis_results"][0] == {
        "student_id": "s1", "match_score": 80, "summary": {"strengths": ["Python"]}
    }


def test_action_records_candidate_failure_without_dropping_other_results(monkeypatch):
    async def fake_evaluate(*args):
        raise RuntimeError("summary unavailable")

    monkeypatch.setattr(action_module, "evaluate_single_candidate", fake_evaluate)
    result = asyncio.run(action_node({"analysis_results": [{"student_id": "s1", "match_score": 80}]}))
    assert result["analysis_results"][0]["summary"] == {"error": "summary unavailable"}


def test_validation_attaches_result_and_sends_webhook(monkeypatch):
    sent = []
    monkeypatch.setattr(validation_module, "run_validation", lambda summary, cv_pdf_url: {"valid": True})
    monkeypatch.setattr("tools.webhook_tool.send_validation_webhook", lambda *args: sent.append(args))
    result = validation_node({
        "job_id": "j1",
        "candidates": [{"UserId": "s1", "CvPdfUrl": "https://example.com/cv.pdf"}],
        "analysis_results": [{"student_id": "s1", "match_score": 80, "summary": {"skills": ["Python"]}}],
    })
    assert result["analysis_results"][0]["validation"] == {"valid": True}
    assert sent[0][:3] == ("s1", "j1", 80)


def test_validation_attaches_error_and_still_reports_it(monkeypatch):
    sent = []

    def fail(*args, **kwargs):
        raise ValueError("CV unreadable")

    monkeypatch.setattr(validation_module, "run_validation", fail)
    monkeypatch.setattr("tools.webhook_tool.send_validation_webhook", lambda *args: sent.append(args))
    result = validation_node({"job_id": "j1", "analysis_results": [{"student_id": "s1"}]})
    assert result["analysis_results"][0]["validation"] == {"error": "CV unreadable"}
    assert sent[0][3]["validation"] == {"error": "CV unreadable"}
