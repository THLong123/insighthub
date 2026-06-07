import asyncio

from app import tools


class FakeResponse:
    def __init__(self, status_code=200, payload=None, text=""):
        self.status_code = status_code
        self._payload = payload if payload is not None else {}
        self.text = text

    def json(self):
        return self._payload


class FakeClient:
    def __init__(self, response):
        self.response = response
        self.request = None

    async def get(self, url, params=None):
        self.request = {"url": url, "params": params}
        return self.response


def test_check_api_health_ok():
    client = FakeClient(FakeResponse(payload={"status": "ok"}))
    result = asyncio.run(tools.check_api_health(client=client))
    assert result["status"] == "ok"
    assert result["http_code"] == 200


def test_check_api_health_server_error():
    client = FakeClient(FakeResponse(status_code=503, payload={"status": "down"}))
    result = asyncio.run(tools.check_api_health(client=client))
    assert result["status"] == "unhealthy"
    assert result["http_code"] == 503


def test_get_ingest_count_today_from_prometheus():
    payload = {"data": {"result": [{"value": [1_700_000_000, "7"]}]}}
    client = FakeClient(FakeResponse(payload=payload))
    result = asyncio.run(tools.get_ingest_count_today(client=client))
    assert result["count"] == 7
    assert result["source"] == "prometheus"


def test_get_ingest_count_today_empty_result():
    client = FakeClient(FakeResponse(payload={"data": {"result": []}}))
    result = asyncio.run(tools.get_ingest_count_today(client=client))
    assert result["count"] == 0
    assert result["source"] == "prometheus_empty"


def test_tool_definitions_include_three_read_tools():
    names = {tool["name"] for tool in tools.TOOL_DEFINITIONS}
    assert names == {"check_api_health", "get_ingest_count_today", "get_failing_pods"}
