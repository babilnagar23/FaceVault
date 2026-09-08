"""
FaceVault API — Application Configuration
All settings are loaded from environment variables via Pydantic Settings.
Never hardcode secrets here.
"""
from functools import lru_cache
from typing import Literal

from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ─── Application ─────────────────────────────────────
    APP_NAME: str = "FaceVault API"
    APP_ENV: Literal["development", "staging", "production"] = "development"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False
    LOG_LEVEL: str = "INFO"
    API_PREFIX: str = "/api/v1"
    DOCS_ENABLED: bool = True

    # ─── Database ─────────────────────────────────────────
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20

    # ─── Redis ────────────────────────────────────────────
    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # ─── Authentication ───────────────────────────────────
    JWT_SECRET_KEY: str
    JWT_REFRESH_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ─── CORS ─────────────────────────────────────────────
    CORS_ORIGINS: str = "http://localhost:3000"

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str) -> list[str]:
        if isinstance(v, list):
            return v
        return [origin.strip() for origin in v.split(",") if origin.strip()]

    # ─── Object Storage ───────────────────────────────────
    S3_ENDPOINT: str = "http://localhost:9000"
    S3_BUCKET: str = "facevault-dev"
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_REGION: str = "us-east-1"
    S3_PRESIGNED_URL_EXPIRE_SECONDS: int = 3600

    # ─── Biometric Thresholds ─────────────────────────────
    FACE_MATCH_THRESHOLD: float = 0.85
    LIVENESS_THRESHOLD: float = 0.80
    MINIMUM_FACE_QUALITY: float = 0.70

    # ─── GPS / Geofence ───────────────────────────────────
    DEFAULT_GEOFENCE_RADIUS_METERS: int = 150
    GPS_ACCURACY_THRESHOLD_METERS: int = 50
    MAX_CLOCK_DRIFT_SECONDS: int = 300

    # ─── Attendance Business Rules ────────────────────────
    GRACE_PERIOD_MINUTES: int = 15
    LATE_THRESHOLD_MINUTES: int = 30
    CHECKIN_WINDOW_HOURS: int = 2
    MAX_OFFLINE_DAYS: int = 7

    # ─── FCM ──────────────────────────────────────────────
    FCM_PROJECT_ID: str = ""
    FCM_CREDENTIALS_PATH: str = ""

    # ─── Monitoring ───────────────────────────────────────
    SENTRY_DSN: str = ""


@lru_cache
def get_settings() -> Settings:
    """Cached settings instance — call this everywhere."""
    return Settings()


settings = get_settings()
