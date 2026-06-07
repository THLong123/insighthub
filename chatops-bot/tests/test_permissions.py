from app.permissions import (
    PermissionTier,
    classify_intent,
    clear_confirmation_tokens,
    issue_confirmation_token,
    validate_confirmation_token,
)


def setup_function():
    clear_confirmation_tokens()


def test_read_intent_is_default():
    assert classify_intent("api healthy?") == PermissionTier.READ


def test_write_intent_detects_scale():
    assert classify_intent("scale api to 3 replicas") == PermissionTier.WRITE


def test_write_intent_detects_restart():
    assert classify_intent("restart web") == PermissionTier.WRITE


def test_destructive_intent_detects_delete():
    assert classify_intent("delete pod api-123") == PermissionTier.DESTRUCTIVE


def test_confirmation_token_is_user_bound():
    token = issue_confirmation_token("U1", "scale api", ttl_seconds=60)
    assert not validate_confirmation_token(token, "U2")


def test_confirmation_token_is_one_time_use():
    token = issue_confirmation_token("U1", "scale api", ttl_seconds=60)
    assert validate_confirmation_token(token, "U1")
    assert not validate_confirmation_token(token, "U1")


def test_expired_confirmation_token_is_rejected():
    token = issue_confirmation_token("U1", "scale api", ttl_seconds=-1)
    assert not validate_confirmation_token(token, "U1")
