from fastapi import FastAPI
from app.middleware import log_requests
from app.routes import general, monitoring

app = FastAPI()

app.middleware("http")(log_requests)

app.include_router(general.router)
app.include_router(monitoring.router)