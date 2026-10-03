import asyncio
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

import main
from main import AnalyzeRequest, ResumeRequest, run_orchestration, resume_orchestration


class FakeGraph:
    def __init__(self):
        self.invocations = []
        self.updated = []

    async def ainvoke(self, state, *, config):
        self.invocations.append((state, config["configurable"]["thread_id"]))
        if state is None:
            return {"analysis_results": [{"student_id": "s1"}], "email_sent": True}
        return {"analysis_results": [{"student_id": state["initial_student_ids"][0]}]}

    async def aget_state(self, config):
        return SimpleNamespace(values={"analysis_results": [{"student_id": "s1"}]}, next=("email",))

    async def aupdate_state(self, config, state):
        self.updated.append((config["configurable"]["thread_id"], state))


def test_analyze_creates_one_paused_thread_per_candidate(monkeypatch):
    graph = FakeGraph()
    request = SimpleNamespace(app=SimpleNamespace(state=SimpleNamespace(graph=graph)))
    result = asyncio.run(run_orchestration(
        AnalyzeRequest(job_id="j1", student_ids=["s1", "s2", "s1"]), request,
    ))
    assert [thread for _, thread in graph.invocations] == ["j1:s1", "j1:s2"]
    assert result["thread_ids"] == {"s1": "j1:s1", "s2": "j1:s2"}
    assert [candidate["student_id"] for candidate in result["results"]] == ["s1", "s2"]


def test_resume_requires_secret_and_paused_single_candidate(monkeypatch):
    graph = FakeGraph()
    request = SimpleNamespace(app=SimpleNamespace(state=SimpleNamespace(graph=graph)))
    monkeypatch.setenv("WEBHOOK_SECRET", "test-secret")
    resume = ResumeRequest(thread_id="j1:s1", human_approved=True,
                           approved_by="admin-1", decision_at="2026-10-05T12:00:00Z")

    with pytest.raises(HTTPException) as denied:
        asyncio.run(resume_orchestration(resume, request, "wrong"))
    assert denied.value.status_code == 401
    assert not graph.updated

    result = asyncio.run(resume_orchestration(resume, request, "test-secret"))
    assert result["status"] == "completed"
    assert result["email_sent"] is True
    assert graph.updated == [("j1:s1", {
        "human_approved": True,
        "approved_by": "admin-1",
        "decision_at": "2026-10-05T12:00:00Z",
    })]
    assert graph.invocations[-1] == (None, "j1:s1")


def test_notification_failure_does_not_complete_silently(monkeypatch):
    monkeypatch.setattr(main, "send_email", lambda *args: False)
    with pytest.raises(RuntimeError, match="did not accept"):
        main.email_node({
            "human_approved": True,
            "candidates": [{"UserId": "s1", "Email": "student@example.edu"}],
            "analysis_results": [{"student_id": "s1"}],
        })


def test_notification_looks_up_email_for_profile_without_email(monkeypatch):
    sent = []

    class Cursor:
        def __enter__(self): return self
        def __exit__(self, *_): pass
        def execute(self, query, params):
            assert params == ("s1",)
        def fetchone(self): return {"Email": "student@example.edu"}

    class Connection:
        def __enter__(self): return self
        def __exit__(self, *_): pass
        def cursor(self): return Cursor()

    monkeypatch.setattr(main, "get_db_connection", lambda: Connection())
    monkeypatch.setattr(main, "send_email", lambda *args: sent.append(args) or True)
    result = main.email_node({
        "human_approved": True,
        "candidates": [{"UserId": "s1"}],
        "analysis_results": [{"student_id": "s1"}],
    })
    assert sent[0][0] == "student@example.edu"
    assert result == {"email_sent": True}
