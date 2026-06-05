import logging

from app.core.config import get_settings
from app.core.db import close_pool, get_pool
from app.core.queue import redis_settings_from_url
from worker.tasks import ingest_document

settings = get_settings()
logging.basicConfig(level=settings.log_level)


async def startup(ctx):
    get_pool()


async def shutdown(ctx):
    close_pool()


class WorkerSettings:
    functions = [ingest_document]
    redis_settings = redis_settings_from_url(settings.redis_url)
    on_startup = startup
    on_shutdown = shutdown
    max_jobs = 4
    job_timeout = 600
