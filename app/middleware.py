import uuid
from fastapi import Request
from app.logger import logger

async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())[:8]

    logger.info("request started", extra={
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
    })

    try:
        response = await call_next(request)
    except Exception:
        logger.exception("request failed", extra={"request_id": request_id})
        raise

    logger.info("request finished", extra={
        "request_id": request_id,
        "status_code": response.status_code,
    })

    return response