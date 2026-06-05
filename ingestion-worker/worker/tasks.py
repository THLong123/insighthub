import asyncio
import logging

from app.core.metrics import ingestion_errors_total
from app.services.ingestion import ingest_document_sync

logger = logging.getLogger("insighthub.ingestion_worker")


async def ingest_document(ctx, document_id: int, filename: str, content: bytes) -> int:
    try:
        return await asyncio.to_thread(
            ingest_document_sync,
            document_id,
            filename,
            content,
        )
    except Exception:
        ingestion_errors_total.inc()
        logger.exception("Ingestion worker failed for document %s", document_id)
        raise
