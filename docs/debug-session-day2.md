# Day 2 Debug Session - MCP

## Scenario

InsightHub has 5 local services. The suspected issue is a failed or unhealthy container after Day 1 async ingestion refactor.

## Prompt

```text
Service nào của InsightHub đang không khỏe? Dùng Docker MCP kiểm tra container,
lấy log service lỗi, xác định nguyên nhân gốc và đề xuất bước sửa.
```

## MCP Tool Flow

1. Docker MCP lists containers for the InsightHub compose project.
2. Docker MCP inspects health status for `api`, `web`, `postgres`, `redis`, and `ingestion-worker`.
3. Docker MCP fetches recent logs for the unhealthy service.
4. Agent summarizes root cause and proposes a targeted fix.

## Observed Debug Result

- `api`, `postgres`, and `redis` are healthy.
- `ingestion-worker` is running and processes ARQ jobs.
- `web` can be marked unhealthy if its `/api/health` probe cannot be reached from inside the container.
- Upload through API still works: `POST /documents` returns `202`, then worker moves the document to `ready`.

## RCA

The async ingestion path is healthy. A failed upload from terminal is more likely caused by Windows PowerShell multipart syntax than by the worker pipeline. Use `curl.exe -F "file=@sample-docs/huong-dan-nguoi-moi.md" http://localhost:8000/documents` or `scripts/verify-day-1.ps1`.

## Follow-Up

- Keep Docker MCP read-only during investigation.
- Use Kubernetes MCP with the `mcp-readonly` ServiceAccount for cluster debugging.
- Use Prometheus MCP after Day 4 when Prometheus is exposed at `PROMETHEUS_URL`.
