"""
Core application configuration settings.
Loads environment variables and provides application-wide configuration.
"""

from pydantic_settings import BaseSettings
from typing import List
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Application
    APP_NAME: str = "Ascent_Fin"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str
    DB_ECHO: bool = True
    
    # Redis
    REDIS_URL: str
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Password Hashing
    BCRYPT_ROUNDS: int = 12
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080"
    ALLOWED_METHODS: str = "GET,POST,PUT,DELETE,PATCH"
    ALLOWED_HEADERS: str = "*"
    
    # M-Pesa
    MPESA_ENVIRONMENT: str = "sandbox"
    MPESA_CONSUMER_KEY: str = ""
    MPESA_CONSUMER_SECRET: str = ""
    MPESA_SHORTCODE: str = ""
    MPESA_PASSKEY: str = ""
    MPESA_INITIATOR_NAME: str = ""
    MPESA_INITIATOR_PASSWORD: str = ""
    MPESA_CALLBACK_URL: str = ""
    MPESA_TIMEOUT_URL: str = ""
    
    # File Upload
    MAX_UPLOAD_SIZE: int = 10485760  # 10MB
    ALLOWED_EXTENSIONS: str = "pdf,png,jpg,jpeg,doc,docx"
    UPLOAD_DIR: str = "./uploads"
    
    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    # Campaign Settings
    MIN_FUNDING_GOAL: int = 10000
    MAX_FUNDING_GOAL: int = 10000000
    FUNDING_GOAL_CEILING: int = 1000000
    MIN_CAMPAIGN_DURATION: int = 30
    MAX_CAMPAIGN_DURATION: int = 365
    
    # Voting Settings
    VOTE_APPROVAL_THRESHOLD: int = 75
    MIN_QUORUM_PERCENTAGE: int = 50
    
    # Escrow Settings
    MIN_REMEDIAL_RESERVE: float = 0.05
    MAX_REMEDIAL_RESERVE: float = 0.15
    MIN_PHASE_COUNT: int = 3
    MAX_PHASE_COUNT: int = 12
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "logs/app.log"
    
    @property
    def allowed_origins_list(self) -> List[str]:
        """Convert ALLOWED_ORIGINS string to list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    @property
    def allowed_methods_list(self) -> List[str]:
        """Convert ALLOWED_METHODS string to list."""
        return [method.strip() for method in self.ALLOWED_METHODS.split(",")]
    
    @property
    def allowed_extensions_list(self) -> List[str]:
        """Convert ALLOWED_EXTENSIONS string to list."""
        return [ext.strip() for ext in self.ALLOWED_EXTENSIONS.split(",")]
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.
    Uses lru_cache to avoid reading .env file multiple times.
    """
    return Settings()


# Global settings instance
settings = get_settings()
