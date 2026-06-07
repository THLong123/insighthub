"""FastAPI entrypoint for the InsightHub ChatOps Slack bot."""

from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
import time
from typing import Mapping

import anyio
from fastapi import BackgroundTasks, FastAPI, HTTPException, Request
from slack_sdk import WebClient

from .handler import handle_question

logging.basicConfig(level="INFO")
logger = logging.getLogger("chatops-bot")

app = FastAPI(title="InsightHub ChatOps Bot")

SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET", "")
SLACK_BOT_TOKEN = os.getenv("SLACK_BOT_TOKEN", "")
SLACK_BOT_USER_ID = os.getenv("SLACK_BOT_USER_ID", "")

slack_client = WebClient(token=SLACK_BOT_TOKEN) if SLACK_BOT_TOKEN else None


@app.get("/healthz")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "chatops-bot"}


def verify_slack_signature(
    headers: Mapping[str, str],
    raw_body: bytes,
    signing_secret: str | None = None,
    now: float | None = None,
) -> bool:
    """Validate Slack HMAC signature and reject replayed requests."""

    signing_secret = SLACK_SIGNING_SECRET if signing_secret is None else signing_secret
    if not signing_secret:
        logger.warning("SLACK_SIGNING_SECRET is empty; skipping Slack signature check")
        return True

    timestamp = headers.get("x-slack-request-timestamp") or headers.get(
        "X-Slack-Request-Timestamp"
    )
    signature = headers.get("x-slack-signature") or headers.get("X-Slack-Signature")
    if not timestamp or not signature:
        return False

    try:
        timestamp_int = int(timestamp)
    except ValueError:
        return False

    current_time = now if now is not None else time.time()
    if abs(current_time - timestamp_int) > 300:
        return False

    base = b"v0:" + timestamp.encode("utf-8") + b":" + raw_body
    expected = "v0=" + hmac.new(
        signing_secret.encode("utf-8"),
        base,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


def _strip_bot_mention(text: str) -> str:
    return " ".join(part for part in text.split() if not part.startswith("<@")).strip()


async def _post_reply(channel: str, thread_ts: str | None, text: str) -> None:
    if not slack_client:
        logger.info("Slack token not configured; reply would be sent to %s: %s", channel, text)
        return
    await anyio.to_thread.run_sync(
        lambda: slack_client.chat_postMessage(
            channel=channel,
            thread_ts=thread_ts,
            text=text,
        )
    )


async def _process_and_reply(event: dict, question: str) -> None:
    user = event.get("user", "unknown")
    channel = event.get("channel", "")
    thread_ts = event.get("thread_ts") or event.get("ts")
    answer = await handle_question(question, user=user)
    if channel:
        await _post_reply(channel, thread_ts, answer)


@app.post("/slack/events")
async def slack_events(request: Request, background_tasks: BackgroundTasks) -> dict:
    raw_body = await request.body()
    if not verify_slack_signature(request.headers, raw_body):
        raise HTTPException(status_code=401, detail="Invalid Slack signature")

    payload = json.loads(raw_body.decode("utf-8") or "{}")

    if payload.get("type") == "url_verification":
        return {"challenge": payload.get("challenge")}

    if payload.get("type") != "event_callback":
        return {"ok": True}

    event = payload.get("event", {})
    if event.get("type") != "app_mention":
        return {"ok": True}
    if SLACK_BOT_USER_ID and event.get("user") == SLACK_BOT_USER_ID:
        return {"ok": True}

    question = _strip_bot_mention(event.get("text", ""))
    if question:
        background_tasks.add_task(_process_and_reply, event, question)
    return {"ok": True}
