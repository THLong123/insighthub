import asyncio

from app import audit, handler
from app.permissions import clear_confirmation_tokens


def setup_function():
    clear_confirmation_tokens()


def test_handle_question_routes_health(monkeypatch, tmp_path):
    async def fake_health():
        return {"status": "ok", "http_code": 200}

    monkeypatch.setitem(handler.TOOLS, "check_api_health", fake_health)
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    answer = asyncio.run(handler.handle_question("api healthy?", user="U1"))
    assert "healthy" in answer
    assert "check_api_health" in (tmp_path / "audit.log").read_text()


def test_handle_question_routes_ingest(monkeypatch, tmp_path):
    async def fake_ingest():
        return {"count": 12}

    monkeypatch.setitem(handler.TOOLS, "get_ingest_count_today", fake_ingest)
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    answer = asyncio.run(handler.handle_question("ingest count today?", user="U1"))
    assert "12" in answer


def test_handle_question_routes_failing_pods(monkeypatch, tmp_path):
    async def fake_pods():
        return {"namespace": "insighthub", "failing_pods": [{"name": "api-1"}]}

    monkeypatch.setitem(handler.TOOLS, "get_failing_pods", fake_pods)
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    answer = asyncio.run(handler.handle_question("which pods failing?", user="U1"))
    assert "api-1" in answer


def test_write_action_requires_confirmation(tmp_path, monkeypatch):
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    answer = asyncio.run(handler.handle_question("scale api to 10 replicas", user="U1"))
    assert "confirm" in answer.lower()
    assert '"approved":false' in (tmp_path / "audit.log").read_text()


def test_destructive_action_is_blocked(tmp_path, monkeypatch):
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    answer = asyncio.run(handler.handle_question("delete pod api-1", user="U1"))
    assert "blocked" in answer.lower()
    assert '"approved":false' in (tmp_path / "audit.log").read_text()


def test_confirmation_flow_succeeds_for_same_user(tmp_path, monkeypatch):
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    first = asyncio.run(handler.handle_question("scale api to 2", user="U1"))
    token = first.split("confirm ", 1)[1].split("`", 1)[0]
    second = asyncio.run(handler.handle_question(f"confirm {token}", user="U1"))
    assert "Confirmed" in second


def test_confirmation_flow_rejects_wrong_user(tmp_path, monkeypatch):
    monkeypatch.setattr(audit, "AUDIT_LOG_PATH", tmp_path / "audit.log")
    monkeypatch.setattr(handler, "log_tool_call", audit.log_tool_call)

    first = asyncio.run(handler.handle_question("scale api to 2", user="U1"))
    token = first.split("confirm ", 1)[1].split("`", 1)[0]
    second = asyncio.run(handler.handle_question(f"confirm {token}", user="U2"))
    assert "invalid" in second.lower()
