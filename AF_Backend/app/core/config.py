from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Ascent Fin"
    APP_NAME: str = "Ascent Fin"
    APP_VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = "YOUR_SUPER_SECRET_KEY_CHANGE_IN_PRODUCTION"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8 # 8 days
    ALGORITHM: str = "HS256"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    allowed_origins_list: list = ["*"]
    allowed_methods_list: list = ["*"]
    ALLOWED_HEADERS: str = "*"
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/ascentfin"
    
    class Config:
        case_sensitive = True

settings = Settings()
