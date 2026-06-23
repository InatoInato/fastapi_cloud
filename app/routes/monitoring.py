import psutil
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health():
    return {"status": "ok"}

@router.get("/metrics")
def metrics():
    return {
        "cpu_percent": psutil.cpu_percent(interval=0.5),
        "ram": {
            "total_mb": round(psutil.virtual_memory().total / 1024 / 1024),
            "used_mb":  round(psutil.virtual_memory().used  / 1024 / 1024),
            "percent":  psutil.virtual_memory().percent,
        },
        "disk": {
            "total_gb": round(psutil.disk_usage("/").total / 1024 / 1024 / 1024, 1),
            "used_gb":  round(psutil.disk_usage("/").used  / 1024 / 1024 / 1024, 1),
            "percent":  psutil.disk_usage("/").percent,
        }
    }