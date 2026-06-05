from fastapi import FastAPI, Request
import logging
import os
from datetime import datetime

# create logs directory
os.makedirs("logs", exist_ok=True)

# setup logger
logging.basicConfig(
    filename="logs/app.log",
    level=logging.INFO,
    format="%(asctime)s - %(message)s"
)

app = FastAPI()

def write_log(msg: str):
    logging.info(msg)
    print(msg)  # also show in terminal (dev mode)

@app.get("/")
def home():
    write_log("GET / called")
    return {"message": "hello cloud world"}

@app.get("/health")
def health():
    write_log("GET /health called")
    return {"status": "ok"}

@app.post("/echo")
async def echo(request: Request):
    data = await request.json()
    write_log(f"POST /echo with data: {data}")
    return {"you_sent": data}