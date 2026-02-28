"""
Main FastAPI application entry point.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

# Create FastAPI app instance
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Crowdfunding platform for Kenyan startups with milestone-based fund release",
    debug=settings.DEBUG,
)

from app.core.scheduler import start_scheduler, stop_scheduler

@app.on_event("startup")
async def startup_event():
    start_scheduler()

@app.on_event("shutdown")
async def shutdown_event():
    stop_scheduler()

# Mount static files for uploads
from fastapi.staticfiles import StaticFiles
import os

# Ensure uploads directory exists
os.makedirs("uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=settings.allowed_methods_list,
    allow_headers=[settings.ALLOWED_HEADERS] if settings.ALLOWED_HEADERS != "*" else ["*"],
)
from app.core.socket_manager import socket_app

# Mount Socket.io app
app.mount("/socket.io", socket_app)

@app.get("/")
async def root():
    """Root endpoint - API health check."""
    return {
        "message": f"Welcome to {settings.APP_NAME} API",
        "version": settings.APP_VERSION,
        "status": "running",
        "environment": settings.ENVIRONMENT,
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring."""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


# API Routes
from app.api.endpoints import auth, campaigns, votes, contributions, milestones
from app.api.v1.endpoints import payments

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Authentication"])
app.include_router(campaigns.router, prefix=f"{settings.API_V1_STR}/campaigns", tags=["Campaigns"])
app.include_router(milestones.router, prefix=f"{settings.API_V1_STR}/milestones", tags=["Milestones"])
app.include_router(votes.router, prefix=f"{settings.API_V1_STR}/votes", tags=["Votes"])
app.include_router(contributions.router, prefix=f"{settings.API_V1_STR}/contributions", tags=["Contributions"])
app.include_router(payments.router, prefix=f"{settings.API_V1_STR}/payments", tags=["Payments"])
