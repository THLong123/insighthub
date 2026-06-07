import hashlib
import hmac
import json
import time

from fastapi.testclient import TestClient

from app import main


def _signed_headers(secret: str, body: bytes, timestamp: int | None = None):
    timestamp = timestamp or int(time.time())
    base = b"v0:" + str(timestamp).encode() + b":" + body
    signature = "v0=" + hmac.new(secret.encode(), base, hashlib.sha256).hexdigest()
    return {
        "x-slack-request-timestamp": str(timestamp),
        "x-slack-signature": signature,
    }


def test_healthz():
    client = TestClient(main.app)
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_url_verification(monkeypatch):
    monkeypatch.setattr(main, "SLACK_SIGNING_SECRET", "secret")
    body = json.dumps({"type": "url_verification", "challenge": "abc"}).encode()
    client = TestClient(main.app)
    response = client.post("/slack/events", content=body, headers=_signed_headers("secret", body))
    assert response.status_code == 200
    assert response.json() == {"challenge": "abc"}


def test_invalid_signature_returns_401(monkeypatch):
    monkeypatch.setattr(main, "SLACK_SIGNING_SECRET", "secret")
    client = TestClient(main.app)
    response = client.post("/slack/events", content=b"{}", headers={})
    assert response.status_code == 401


def test_non_event_callback_is_accepted(monkeypatch):
    monkeypatch.setattr(main, "SLACK_SIGNING_SECRET", "")
    client = TestClient(main.app)
    response = client.post("/slack/events", json={"type": "app_rate_limited"})
    assert response.status_code == 200
    assert response.json() == {"ok": True}


def test_strip_bot_mention():
    assert main._strip_bot_mention("<@BOT> api healthy?") == "api healthy?"


def test_app_mention_queues_background_task(monkeypatch):
    monkeypatch.setattr(main, "SLACK_SIGNING_SECRET", "")

    async def fake_process(event, question):
        assert event["user"] == "U1"
        assert question == "api healthy?"

    monkeypatch.setattr(main, "_process_and_reply", fake_process)
    payload = {
        "type": "event_callback",
        "event": {
            "type": "app_mention",
            "user": "U1",
            "channel": "C1",
            "text": "<@BOT> api healthy?",
            "ts": "1",
        },
    }
    client = TestClient(main.app)
    response = client.post("/slack/events", json=payload)
    assert response.status_code == 200
    assert response.json() == {"ok": True}
