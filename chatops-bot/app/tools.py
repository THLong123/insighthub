"""Operational tools exposed to the ChatOps handler."""

from __future__ import annotations

import asyncio
import json
import os
from typing import Any

import httpx


INSIGHTHUB_API_URL = os.getenv("INSIGHTHUB_API_URL", "http://localhost:8000")
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://localhost:9090")
K8S_NAMESPACE = os.getenv("K8S_NAMESPACE", "insighthub")


TOOL_DEFINITIONS: list[dict[str, Any]] = [
    {
        "name": "check_api_health",
        "description": "Check InsightHub API /health endpoint.",
        "input_schema": {"type": "object", "properties": {}},
    },
    {
        "name": "get_ingest_count_today",
        "description": "Get today's document ingestion count from Prometheus.",
        "input_schema": {"type": "object", "properties": {}},
    },
    {
        "name": "get_failing_pods",
        "description": "List Kubernetes pods that are not healthy.",
        "input_schema": {"type": "object", "properties": {}},
    },
]


async def check_api_health(client: httpx.AsyncClient | None = None) -> dict[str, Any]:
    close_client = client is None
    client = client or httpx.AsyncClient(timeout=5)
    try:
        response = await client.get(f"{INSIGHTHUB_API_URL.rstrip('/')}/health")
        data: Any
        try:
            data = response.json()
        except ValueError:
            data = response.text[:200]
        return {
            "status": "ok" if response.status_code < 500 else "unhealthy",
            "http_code": response.status_code,
            "body": data,
            "source": "insighthub_api",
        }
    except Exception as exc:  # pragma: no cover - exact network failures vary
        return {
            "status": "unreachable",
            "error": str(exc),
            "source": "insighthub_api",
        }
    finally:
        if close_client:
            await client.aclose()


async def get_ingest_count_today(client: httpx.AsyncClient | None = None) -> dict[str, Any]:
    close_client = client is None
    client = client or httpx.AsyncClient(timeout=5)
    query = 'increase(insighthub_ingestion_jobs_total{status="ready"}[24h])'
    try:
        response = await client.get(
            f"{PROMETHEUS_URL.rstrip('/')}/api/v1/query",
            params={"query": query},
        )
        payload = response.json()
        results = payload.get("data", {}).get("result", [])
        if not results:
            return {"count": 0, "source": "prometheus_empty", "query": query}
        value = float(results[0]["value"][1])
        return {"count": int(value), "source": "prometheus", "query": query}
    except Exception as exc:  # pragma: no cover - exact network failures vary
        return {"count": 0, "source": "prometheus_error", "query": query, "error": str(exc)}
    finally:
        if close_client:
            await client.aclose()


async def get_failing_pods(namespace: str = K8S_NAMESPACE) -> dict[str, Any]:
    cmd = [
        "kubectl",
        "get",
        "pods",
        "-n",
        namespace,
        "-o",
        "json",
        "--request-timeout=5s",
    ]
    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await proc.communicate()
        if proc.returncode != 0:
            return {
                "namespace": namespace,
                "failing_pods": [],
                "source": "kubectl_error",
                "error": stderr.decode("utf-8", errors="replace")[:300],
            }
        payload = json.loads(stdout.decode("utf-8"))
    except Exception as exc:  # pragma: no cover - exact local kubectl state varies
        return {
            "namespace": namespace,
            "failing_pods": [],
            "source": "kubectl_error",
            "error": str(exc),
        }

    failing = []
    for item in payload.get("items", []):
        phase = item.get("status", {}).get("phase")
        waiting = [
            status.get("state", {}).get("waiting", {}).get("reason")
            for status in item.get("status", {}).get("containerStatuses", [])
            if status.get("state", {}).get("waiting")
        ]
        if phase not in ("Running", "Succeeded") or waiting:
            failing.append(
                {
                    "name": item.get("metadata", {}).get("name", "unknown"),
                    "phase": phase,
                    "reasons": [reason for reason in waiting if reason],
                }
            )

    return {"namespace": namespace, "failing_pods": failing, "source": "kubectl"}
