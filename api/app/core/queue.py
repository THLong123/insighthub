from arq import create_pool
from arq.connections import RedisSettings

from app.core.config import get_settings
from app.core.metrics import ingestion_queue_depth

ARQ_QUEUE_NAME = "arq:queue"


def redis_settings_from_url(redis_url: str) -> RedisSettings:
    return RedisSettings.from_dsn(redis_url)


async def create_redis_pool():
    settings = get_settings()
    return await create_pool(redis_settings_from_url(settings.redis_url))


async def refresh_ingestion_queue_depth(redis) -> int:
    depth = await redis.zcard(ARQ_QUEUE_NAME)
    ingestion_queue_depth.set(depth)
    return depth
