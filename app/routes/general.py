from fastapi import APIRouter, Request
from app.logger import logger

router = APIRouter()

@router.get("/")
def home():
    return {"message": "hello cloud world"}

@router.get("/version")
def version():
    return {"version": "1.3"}

@router.post("/echo")
async def echo(request: Request):
    data = await request.json()
    logger.info("echo called", extra={"payload_size": len(str(data))})
    return {"you_sent": data}