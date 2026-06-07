"""Three-tier permission model for ChatOps actions."""

from __future__ import annotations

import secrets
import time
from dataclasses import dataclass
from enum import Enum


class PermissionTier(str, Enum):
    READ = "read"
    WRITE = "write"
    DESTRUCTIVE = "destructive"


DESTRUCTIVE_KEYWORDS = (
    "delete",
    "destroy",
    "remove pod",
    "drop",
    "truncate",
    "wipe",
    "xoa",
    "xóa",
)

WRITE_KEYWORDS = (
    "scale",
    "restart",
    "rollout",
    "deploy",
    "patch",
    "cordon",
    "uncordon",
)


@dataclass
class Confirmation:
    user: str
    action: str
    expires_at: float


_TOKENS: dict[str, Confirmation] = {}


def classify_intent(text: str) -> PermissionTier:
    normalized = text.lower()
    if any(keyword in normalized for keyword in DESTRUCTIVE_KEYWORDS):
        return PermissionTier.DESTRUCTIVE
    if any(keyword in normalized for keyword in WRITE_KEYWORDS):
        return PermissionTier.WRITE
    return PermissionTier.READ


def issue_confirmation_token(user: str, action: str, ttl_seconds: int = 60) -> str:
    token = secrets.token_urlsafe(16)
    _TOKENS[token] = Confirmation(
        user=user,
        action=action,
        expires_at=time.monotonic() + ttl_seconds,
    )
    return token


def validate_confirmation_token(token: str, user: str) -> bool:
    confirmation = _TOKENS.pop(token, None)
    if confirmation is None:
        return False
    if confirmation.user != user:
        return False
    return time.monotonic() <= confirmation.expires_at


def clear_confirmation_tokens() -> None:
    _TOKENS.clear()
