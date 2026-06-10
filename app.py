import logging
import sys
import uuid
from pythonjsonlogger import jsonlogger
from fastapi import FastAPI, Request

def setup_logger():
    logger = logging.getLogger()
    handler = logging.StreamHandler(sys.stdout)
    formatter = jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(name)s %(levelname)s %(message)s"
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger

logger = setup_logger()
app = FastAPI()

# middleware — adds request_id to every single log automatically
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())[:8]
    
    logger.info("request started", extra={
        "request_id": request_id,
        "method": request.method,
        "path": request.url.path,
    })
    
    response = await call_next(request)
    
    logger.info("request finished", extra={
        "request_id": request_id,
        "status_code": response.status_code,
    })
    
    return response

app.get("/version")
def version():
    return {"version": "1.0"}

@app.get("/")
def home():
    return {"message": "hello cloud world"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/echo")
async def echo(request: Request):
    data = await request.json()
    logger.info("echo called", extra={"payload_size": len(str(data))})
    return {"you_sent": data}