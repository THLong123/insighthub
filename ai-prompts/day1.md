# Day 1 AI Prompt Log

## Prompt 1

```text
Read the InsightHub codebase and summarize the current architecture, especially the document upload and ingestion flow.
```

## Result 1

- API received uploaded files and inserted `documents` rows.
- Ingestion was synchronous through `api/app/services/ingestion.py`.
- `ingestion-worker/` existed as an empty Day 1 exercise target.

## Prompt 2

```text
Refactor synchronous ingestion into an async worker using Redis and ARQ. Keep the API fast, return 202, and make worker processing retry-safe.
```

## Result 2

- Added Redis/ARQ enqueue path in the API.
- Added `ingestion-worker/worker/tasks.py` and `settings.py`.
- Updated `docker-compose.yml` to run `redis` and `ingestion-worker`.
- Made chunk insertion retry-safe by deleting old chunks for the document before reinsert.

## Prompt 3

```text
Add one small AI-augmented feature that fits a RAG notebook and does not require a risky schema migration.
```

## Result 3

- Added `GET /documents/{document_id}/summary`.
- The endpoint summarizes ready documents from existing chunks using the LLM service.
- It works with the existing fallback mode when external LLM credentials are missing.

## Prompt 4

```text
Create Day 1 evidence artifacts so the workflow is auditable by a reviewer.
```

## Result 4

- Updated `agent/day1.md`.
- Added this prompt log at `ai-prompts/day1.md`.
