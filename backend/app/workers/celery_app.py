"""
FaceVault — Celery application factory.
Workers consume tasks from Redis broker.
"""
from celery import Celery
from celery.schedules import crontab

from app.config import settings

celery_app = Celery(
    "facevault",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.workers.tasks"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,  # Fair dispatch
    result_expires=3600,
)

# ─── Beat Schedule (recurring jobs) ──────────────────────────────────────────
celery_app.conf.beat_schedule = {
    # Mark absent employees at end of day
    "daily-absence-reconciliation": {
        "task": "app.workers.tasks.reconcile_absent_employees",
        "schedule": crontab(hour=22, minute=0),  # 10 PM UTC daily
    },
    # Clean up old sync events (> 30 days)
    "cleanup-old-sync-events": {
        "task": "app.workers.tasks.cleanup_old_sync_events",
        "schedule": crontab(hour=3, minute=0, day_of_week="sunday"),
    },
    # Publish scheduled announcements
    "publish-scheduled-announcements": {
        "task": "app.workers.tasks.publish_scheduled_announcements",
        "schedule": crontab(minute="*/5"),  # Every 5 minutes
    },
}
