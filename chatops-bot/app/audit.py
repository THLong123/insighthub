"""Append-only NDJSON audit log for ChatOps tool calls."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _default_audit_path() -> Path:
    configured = os.getenv("AUDIT_LOG_PATH")
    if configured:
        return Path(configured)

    if Path.cwd().name == "chatops-bot":
        return Path("chatops-audit.log")
    return Path("chatops-bot") / "chatops-audit.log"


AUDIT_LOG_PATH = _default_audit_path()


def log_tool_call(
    user: str,
    tool: str,
    args: dict[str, Any],
    result_summary: str,
    approved: bool = True,
) -> dict[str, Any]:
    """Write one audit record and return it for tests/observability."""

    record = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "user": user,
        "tool": tool,
        "args": args,
        "result": result_summary,
        "approved": approved,
    }

    AUDIT_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with AUDIT_LOG_PATH.open("a", encoding="utf-8") as fp:
        fp.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")))
        fp.write("\n")

    return record
