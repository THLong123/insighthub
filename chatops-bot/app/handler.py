"""ChatOps question handler with offline-safe tool calling."""

from __future__ import annotations

import json
import re
from typing import Any, Awaitable, Callable

from .audit import log_tool_call
from .permissions import (
    PermissionTier,
    classify_intent,
    issue_confirmation_token,
    validate_confirmation_token,
)
from .tools import TOOL_DEFINITIONS, check_api_health, get_failing_pods, get_ingest_count_today


ToolFn = Callable[..., Awaitable[dict[str, Any]]]


TOOLS: dict[str, ToolFn] = {
    "check_api_health": check_api_health,
    "get_ingest_count_today": get_ingest_count_today,
    "get_failing_pods": get_failing_pods,
}


def _select_tool(question: str) -> str:
    normalized = question.lower()
    if any(word in normalized for word in ("ingest", "document", "doc", "tai lieu", "tài liệu")):
        return "get_ingest_count_today"
    if any(word in normalized for word in ("pod", "pods", "failing", "loi", "lỗi", "error")):
        return "get_failing_pods"
    return "check_api_health"


def _summarize_tool_result(tool_name: str, result: dict[str, Any]) -> str:
    if tool_name == "check_api_health":
        status = result.get("status", "unknown")
        code = result.get("http_code", "n/a")
        if status == "ok":
            return f"InsightHub API is healthy. HTTP {code}."
        return f"InsightHub API is not healthy: {json.dumps(result, ensure_ascii=False)}"

    if tool_name == "get_ingest_count_today":
        return f"Today ingestion count is {result.get('count', 0)} documents."

    if tool_name == "get_failing_pods":
        pods = result.get("failing_pods", [])
        if not pods:
            return f"No failing pods found in namespace {result.get('namespace', 'insighthub')}."
        names = ", ".join(pod.get("name", "unknown") for pod in pods)
        return f"Failing pods: {names}."

    return json.dumps(result, ensure_ascii=False)


async def handle_question(question: str, user: str = "unknown") -> str:
    """Answer one Slack question and audit every tool/action decision."""

    confirmation = re.fullmatch(r"\s*confirm\s+(\S+)\s*", question, flags=re.IGNORECASE)
    if confirmation:
        token = confirmation.group(1)
        approved = validate_confirmation_token(token, user)
        log_tool_call(
            user=user,
            tool="confirm_write_action",
            args={"token": token[:6] + "..."},
            result_summary="approved" if approved else "invalid_or_expired",
            approved=approved,
        )
        if approved:
            return "Confirmed. Write action approval recorded for the next controlled execution step."
        return "Confirmation token is invalid, expired, or belongs to another user."

    tier = classify_intent(question)
    if tier == PermissionTier.DESTRUCTIVE:
        log_tool_call(
            user=user,
            tool="permission_guard",
            args={"question": question, "tier": tier.value},
            result_summary="destructive action blocked",
            approved=False,
        )
        return "Destructive actions are blocked. Use the incident runbook and a human approver."

    if tier == PermissionTier.WRITE:
        token = issue_confirmation_token(user=user, action=question)
        log_tool_call(
            user=user,
            tool="permission_guard",
            args={"question": question, "tier": tier.value},
            result_summary="confirmation required",
            approved=False,
        )
        return f"Confirm required: reply `confirm {token}` within 60 seconds."

    tool_name = _select_tool(question)
    tool = TOOLS[tool_name]
    result = await tool()
    answer = _summarize_tool_result(tool_name, result)
    log_tool_call(
        user=user,
        tool=tool_name,
        args={"question": question},
        result_summary=answer,
        approved=True,
    )
    return answer


__all__ = ["TOOL_DEFINITIONS", "handle_question"]
