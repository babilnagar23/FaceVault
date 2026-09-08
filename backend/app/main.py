"""
FaceVault API — Application Entry Point
"""
import sentry_sdk
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.router import api_router
from app.config import settings
from app.core.exceptions import FaceVaultException
from app.core.logging import configure_logging
from app.core.middleware import RequestIDMiddleware, RequestLoggingMiddleware

# Configure structured logging early
configure_logging()

# Sentry integration (no-op if DSN is empty)
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment=settings.APP_ENV,
        traces_sample_rate=0.1,
    )


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "FaceVault biometric attendance management API. "
            "Powers the Flutter employee app and Next.js admin dashboard."
        ),
        openapi_url=f"{settings.API_PREFIX}/openapi.json" if settings.DOCS_ENABLED else None,
        docs_url="/docs" if settings.DOCS_ENABLED else None,
        redoc_url="/redoc" if settings.DOCS_ENABLED else None,
    )

    # ─── Middleware (order matters — outermost applied last) ──────────────
    app.add_middleware(RequestLoggingMiddleware)
    app.add_middleware(RequestIDMiddleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ─── Global exception handler ─────────────────────────────────────────
    @app.exception_handler(FaceVaultException)
    async def facevault_exception_handler(
        request: Request, exc: FaceVaultException
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message, "details": exc.details}},
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        import structlog

        log = structlog.get_logger()
        log.error("unhandled_exception", exc_info=exc, path=str(request.url))
        return JSONResponse(
            status_code=500,
            content={
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "An unexpected error occurred.",
                    "details": {},
                }
            },
        )

    # ─── Routers ──────────────────────────────────────────────────────────
    app.include_router(api_router, prefix=settings.API_PREFIX)

    # ─── Health endpoints (outside versioned prefix) ───────────────────────
    @app.get("/health", tags=["System"], summary="Process health check")
    async def health() -> dict:
        return {
            "status": "ok",
            "service": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "environment": settings.APP_ENV,
        }

    @app.get("/ready", tags=["System"], summary="Readiness check (DB + Redis)")
    async def ready() -> dict:
        checks: dict[str, str] = {}

        # Database check
        try:
            from app.db.session import engine
            from sqlalchemy import text

            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            checks["database"] = "ok"
        except Exception as e:
            checks["database"] = f"error: {e}"

        # Redis check
        try:
            import redis.asyncio as aioredis

            r = aioredis.from_url(settings.REDIS_URL)
            await r.ping()
            await r.aclose()
            checks["redis"] = "ok"
        except Exception as e:
            checks["redis"] = f"error: {e}"

        all_ok = all(v == "ok" for v in checks.values())
        return {
            "status": "ok" if all_ok else "degraded",
            "checks": checks,
        }

    return app


app = create_app()
