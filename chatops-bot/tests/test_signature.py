import hashlib
import hmac

from app.main import verify_slack_signature


def _headers(secret: str, body: bytes, timestamp: int = 1_700_000_000):
    base = b"v0:" + str(timestamp).encode() + b":" + body
    signature = "v0=" + hmac.new(secret.encode(), base, hashlib.sha256).hexdigest()
    return {
        "x-slack-request-timestamp": str(timestamp),
        "x-slack-signature": signature,
    }


def test_valid_signature_is_accepted():
    secret = "test-secret"
    body = b'{"type":"event_callback"}'
    assert verify_slack_signature(_headers(secret, body), body, secret, now=1_700_000_001)


def test_missing_signature_is_rejected():
    assert not verify_slack_signature({}, b"{}", "test-secret", now=1_700_000_001)


def test_bad_signature_is_rejected():
    headers = {
        "x-slack-request-timestamp": "1700000000",
        "x-slack-signature": "v0=bad",
    }
    assert not verify_slack_signature(headers, b"{}", "test-secret", now=1_700_000_001)


def test_old_timestamp_is_rejected():
    secret = "test-secret"
    body = b"{}"
    assert not verify_slack_signature(_headers(secret, body), body, secret, now=1_700_000_999)


def test_empty_secret_allows_local_development():
    assert verify_slack_signature({}, b"{}", "", now=1_700_000_001)
