"""
Health check routes
"""
from fastapi import APIRouter
from app.models.schemas import HealthResponse
from app.core.config import settings
from app.core.cache import cache_manager

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint
    Returns API status and configuration info
    """
    return HealthResponse(
        status="ok",
        version="1.0.0",
        environment=settings.ENVIRONMENT,
        api_configured=settings.is_configured(),
        cache_stats=cache_manager.get_stats()
    )


@router.get("/ping")
async def ping():
    """Simple ping endpoint"""
    return {"message": "pong"}
