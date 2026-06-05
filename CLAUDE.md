# InsightHub Project Guide

## Du an

InsightHub la ung dung RAG Notebook. Nguoi dung upload tai lieu `.txt`, `.md`
hoac `.pdf`, sau do hoi dap va tao tom tat dua tren noi dung da ingest.

Day 1 da refactor ingestion tu xu ly dong bo trong API sang Redis queue va ARQ
worker. API tra HTTP `202 Accepted` ngay sau khi enqueue job.

## Kien truc

- `web`: Next.js 15 App Router, giao dien upload va chat, chay tai port `3000`.
- `api`: FastAPI gateway, chay tai port `8000`. API luu metadata tai lieu voi
  status `pending`, enqueue ARQ job vao Redis, phuc vu chat va metrics.
- `ingestion-worker`: ARQ worker doc job tu Redis, extract text, chunk, tao
  embedding va ghi chunks vao PostgreSQL. Worker co the retry an toan.
- `redis`: Redis 7, lam job queue cho ingestion bat dong bo.
- `postgres`: PostgreSQL 16 voi pgvector `0.8.2`, luu documents, chunks va
  vector embeddings.
- `ollama`: service tuy chon khi chay profile `ollama`, dung cho LLM va
  embedding local.

Luong upload tai lieu:

```text
web -> POST /documents -> api -> documents(status=pending)
                              -> Redis ARQ queue
                              -> ingestion-worker
                              -> extract -> chunk -> embed
                              -> PostgreSQL documents(status=ready) + chunks
```

## Quy uoc code

- Python tuan theo PEP 8, dung type hints cho code moi.
- FastAPI router dat trong `api/app/routers/`.
- Logic nghiep vu dung chung dat trong `api/app/services/`.
- Cau hinh runtime doc tu bien moi truong qua `api/app/core/config.py`.
- Khong hardcode API key, token hoac secret trong source code.
- Commit message dung conventional commits: `feat:`, `fix:`, `refactor:`,
  `docs:`, `test:`.
- Khong sua thu muc `insighthub/` long ben trong repo khi lam artifact chinh;
  source dang lam viec nam tai thu muc goc.

## Lenh thuong dung

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f api
docker compose logs -f ingestion-worker
docker compose down
```

Kiem tra Day 1 tren Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify-day-1.ps1
```

Kiem tra tren Linux hoac Git Bash:

```bash
bash scripts/verify-day-1.sh
```

## Luu y quan trong cho AI agent

- `EMBEDDING_DIM` phai khop voi `VECTOR(n)` trong `infra/db/init.sql`. Gia tri
  mac dinh hien tai la `1024`.
- pgvector phai giu phien ban `>= 0.8.2`.
- `process_document()` phai idempotent vi ARQ worker co the retry job. Ham hien
  xoa chunks cu cua document truoc khi insert lai.
- Upload thanh cong tra HTTP `202` voi status `pending`, khong cho status
  `ready` ngay lap tuc.
- API va worker phai dung cung `DATABASE_URL`, `REDIS_URL` va cau hinh
  embedding provider.
- Queue depth metric duoc cap nhat qua `insighthub_ingestion_queue_depth`.
- Feature AI Day 1 la `GET /documents/{document_id}/summary`; chi tom tat tai
  lieu da co status `ready`.
- `scripts/smoke-test.sh` la smoke test v0 cu. Uu tien
  `scripts/verify-day-1.ps1` de verify ingestion async tren Windows.

## Viec dang lam / TODO

- [x] Day 1: tach ingestion-worker, them Redis, them summary endpoint va prompt log
- [ ] Day 2: cau hinh MCP servers
- [ ] Day 3: Terraform + CI/CD pipeline
- [ ] Day 4: observability + anomaly detection
- [ ] Day 5: ChatOps bot
- [ ] Day 6: security hardening + cost monitoring
- [ ] Day 7: hoan thien + demo
