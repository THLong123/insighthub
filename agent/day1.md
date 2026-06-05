# Day 1

## Checklist

- [x] Khoi tao `CLAUDE.md` voi cau truc 6 section.
- [x] Dung Claude Code doc hieu codebase.
- [x] REFACTOR: tach ingestion sync sang `ingestion-worker/` va Redis queue bang ARQ.
- [x] Them 1 feature moi AI-augmented.
- [x] Luu AI prompt log chung minh workflow.

## 7-Day Roadmap

- [x] Day 1: tach ingestion-worker, them Redis
- [ ] Day 2: cau hinh MCP servers
- [ ] Day 3: Terraform + CI/CD pipeline
- [ ] Day 4: observability + anomaly detection
- [ ] Day 5: ChatOps bot
- [ ] Day 6: security hardening + cost monitoring
- [ ] Day 7: hoan thien + demo

## CLAUDE.md 6-section

1. Du an
2. Kien truc
3. Quy uoc code
4. Lenh thuong dung
5. Luu y quan trong cho AI agent
6. Viec dang lam / TODO

## Claude Code Read-Codebase Notes

- Muc tieu: hieu kien truc hien tai, cac service chinh, luong ingestion, API, web va ha tang Docker.
- Can doc: `README.md`, `GETTING_STARTED.md`, `docker-compose.yml`, `api/`, `web/`, `ingestion-worker/`, `infra/`.
- Ket qua mong doi: tom tat duoc luong du lieu tu upload tai lieu den truy van RAG.

## Refactor Plan

- Tach xu ly ingestion dang sync ra service rieng trong `ingestion-worker/`.
- Them Redis lam message broker.
- Dung ARQ de enqueue job ingestion va worker xu ly bat dong bo.
- API chi nhan request, tao job va tra trang thai/job id.
- Worker xu ly document idempotent de co the retry an toan.

## AI-Augmented Feature

- Da them endpoint `GET /documents/{document_id}/summary`.
- Tinh nang dung chunks cua tai lieu da ingest va LLM service de tao tom tat ngan.
- Neu khong co LLM key, he thong van dung fallback extractive co san.

## AI Prompt Log

```text
Prompt 1:
Hay doc codebase va tom tat kien truc InsightHub, dac biet la luong upload/ingestion tai lieu.

Prompt 2:
Hay de xuat cach refactor ingestion sync sang async worker dung Redis queue va ARQ, giu API don gian va worker idempotent.

Prompt 3:
Hay them mot feature AI-augmented phu hop voi RAG Notebook, uu tien tinh nang nho nhung co gia tri cho nguoi dung.

Prompt 4:
Hay cap nhat CLAUDE.md de AI agent cac phien sau hieu kien truc, quy uoc code, lenh thuong dung va TODO cua du an.
```
