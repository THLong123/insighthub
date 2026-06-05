"""
InsightHub API — Documents router
Upload tài liệu và xem trạng thái.

⚠️  Day 1 refactor: endpoint upload hiện gọi ingest ĐỒNG BỘ.
Sau refactor sẽ: lưu metadata → enqueue ARQ job → trả về 202 ngay.
"""
import logging

from fastapi import APIRouter, HTTPException, Request, UploadFile

from app.core.db import get_conn
from app.core.metrics import documents_total, ingestion_errors_total
from app.core.queue import refresh_ingestion_queue_depth
from app.services.llm import generate

logger = logging.getLogger("insighthub.routers.documents")
router = APIRouter(prefix="/documents", tags=["documents"])

ALLOWED_EXT = (".txt", ".md", ".pdf")
MAX_SIZE_MB = 10


@router.post("", status_code=202)
async def upload_document(request: Request, file: UploadFile):
    if not file.filename or not file.filename.lower().endswith(ALLOWED_EXT):
        raise HTTPException(400, f"Chỉ chấp nhận: {', '.join(ALLOWED_EXT)}")

    content = await file.read()
    if len(content) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(413, f"File vượt quá {MAX_SIZE_MB}MB")

    # Lưu metadata, trạng thái 'pending'
    with get_conn() as conn:
        row = conn.execute(
            "INSERT INTO documents (filename, status) VALUES (%s, 'pending') RETURNING id",
            (file.filename,),
        ).fetchone()
        document_id = row[0]

    try:
        job = await request.app.state.redis.enqueue_job(
            "ingest_document",
            document_id,
            file.filename,
            content,
        )
        await refresh_ingestion_queue_depth(request.app.state.redis)
    except Exception as exc:  # noqa: BLE001
        ingestion_errors_total.inc()
        with get_conn() as conn:
            conn.execute(
                "UPDATE documents SET status = 'failed' WHERE id = %s",
                (document_id,),
            )
        raise HTTPException(503, f"Không enqueue được ingestion job: {exc}") from exc

    return {
        "id": document_id,
        "filename": file.filename,
        "status": "pending",
        "chunk_count": 0,
        "job_id": job.job_id if job else None,
    }


@router.get("")
async def list_documents():
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, filename, status, chunk_count, created_at "
            "FROM documents ORDER BY created_at DESC"
        ).fetchall()

    # Cập nhật gauge cho Prometheus
    counts: dict[str, int] = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    for status in ("pending", "ready", "failed"):
        documents_total.labels(status=status).set(counts.get(status, 0))

    return [
        {
            "id": r[0],
            "filename": r[1],
            "status": r[2],
            "chunk_count": r[3],
            "created_at": r[4].isoformat() if r[4] else None,
        }
        for r in rows
    ]


@router.get("/{document_id}/summary")
async def summarize_document(document_id: int):
    with get_conn() as conn:
        document = conn.execute(
            "SELECT id, filename, status FROM documents WHERE id = %s",
            (document_id,),
        ).fetchone()
        if document is None:
            raise HTTPException(404, "Khong tim thay tai lieu")
        if document[2] != "ready":
            raise HTTPException(409, "Tai lieu chua san sang de tom tat")

        rows = conn.execute(
            """
            SELECT chunk_text
            FROM chunks
            WHERE document_id = %s
            ORDER BY id
            LIMIT 8
            """,
            (document_id,),
        ).fetchall()

    if not rows:
        return {
            "id": document[0],
            "filename": document[1],
            "summary": "Tai lieu nay chua co noi dung de tom tat.",
            "sources": [document[1]],
        }

    contexts = [
        {"source": document[1], "chunk_text": row[0]}
        for row in rows
    ]
    result = generate(
        "Tom tat tai lieu nay trong 3-5 gach dau dong ngan gon.",
        contexts,
    )

    return {
        "id": document[0],
        "filename": document[1],
        "summary": result["answer"],
        "sources": result["sources"],
        "usage": result["usage"],
    }


@router.delete("/{document_id}", status_code=204)
async def delete_document(document_id: int):
    with get_conn() as conn:
        result = conn.execute(
            "DELETE FROM documents WHERE id = %s RETURNING id", (document_id,)
        ).fetchone()
    if result is None:
        raise HTTPException(404, "Không tìm thấy tài liệu")
