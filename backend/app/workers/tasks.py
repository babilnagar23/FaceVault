"""
FaceVault — Celery tasks.
All DB access uses synchronous SQLAlchemy sessions (Celery workers are sync).
"""
import asyncio
from datetime import UTC, datetime, timedelta

from app.workers.celery_app import celery_app


def _get_sync_session():
    """Create a synchronous SQLAlchemy session for Celery tasks."""
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker
    from app.config import settings

    # Convert async URL to sync URL
    sync_url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    engine = create_engine(sync_url, pool_pre_ping=True)
    Session = sessionmaker(bind=engine)
    return Session()


@celery_app.task(name="app.workers.tasks.reconcile_absent_employees", bind=True)
def reconcile_absent_employees(self):
    """
    Daily job: For every active employee that has no AttendanceRecord for today,
    create an ABSENT record.
    """
    from app.db.models.attendance_record import AttendanceRecord
    from app.db.models.assignment import Assignment
    from app.db.models.user import User

    session = _get_sync_session()
    try:
        today = datetime.now(UTC).date()
        active_users = session.query(User).filter(User.status == "ACTIVE").all()
        created = 0
        for user in active_users:
            existing = session.query(AttendanceRecord).filter(
                AttendanceRecord.user_id == user.id,
                AttendanceRecord.attendance_date == today,
            ).first()
            if not existing:
                assignment = session.query(Assignment).filter(
                    Assignment.user_id == user.id,
                    Assignment.is_active == True,
                ).first()
                record = AttendanceRecord(
                    organization_id=user.organization_id,
                    user_id=user.id,
                    assignment_id=assignment.id if assignment else None,
                    project_id=assignment.project_id if assignment else None,
                    location_id=assignment.location_id if assignment else None,
                    shift_id=assignment.shift_id if assignment else None,
                    attendance_date=today,
                    status="ABSENT",
                    source="SYSTEM",
                )
                session.add(record)
                created += 1
        session.commit()
        return {"date": today.isoformat(), "absent_records_created": created}
    except Exception as exc:
        session.rollback()
        raise self.retry(exc=exc, countdown=60, max_retries=3)
    finally:
        session.close()


@celery_app.task(name="app.workers.tasks.cleanup_old_sync_events", bind=True)
def cleanup_old_sync_events(self):
    """Delete sync_events older than 30 days."""
    from app.db.models.sync_event import SyncEvent

    session = _get_sync_session()
    try:
        cutoff = datetime.now(UTC) - timedelta(days=30)
        deleted = session.query(SyncEvent).filter(SyncEvent.created_at < cutoff).delete()
        session.commit()
        return {"deleted": deleted}
    except Exception as exc:
        session.rollback()
        raise self.retry(exc=exc, countdown=300, max_retries=2)
    finally:
        session.close()


@celery_app.task(name="app.workers.tasks.publish_scheduled_announcements", bind=True)
def publish_scheduled_announcements(self):
    """Publish announcements whose scheduled_for has passed."""
    from app.db.models.announcement import Announcement

    session = _get_sync_session()
    try:
        now = datetime.now(UTC)
        due = session.query(Announcement).filter(
            Announcement.status == "SCHEDULED",
            Announcement.scheduled_for <= now,
        ).all()
        for ann in due:
            ann.status = "PUBLISHED"
            ann.published_at = now
        session.commit()
        return {"published": len(due)}
    except Exception as exc:
        session.rollback()
        raise self.retry(exc=exc, countdown=60, max_retries=3)
    finally:
        session.close()


@celery_app.task(name="app.workers.tasks.export_attendance_report", bind=True)
def export_attendance_report(self, org_id: str, date_from: str, date_to: str, format: str, requested_by: str):
    """
    Generate and upload an attendance report to S3/MinIO.
    Returns a presigned download URL.
    """
    import csv
    import io
    from app.db.models.attendance_record import AttendanceRecord
    from app.db.models.user import User

    session = _get_sync_session()
    try:
        from datetime import date
        from app.config import settings
        import boto3

        from_date = date.fromisoformat(date_from)
        to_date = date.fromisoformat(date_to)

        records = (
            session.query(AttendanceRecord, User)
            .join(User, AttendanceRecord.user_id == User.id)
            .filter(
                AttendanceRecord.organization_id == org_id,
                AttendanceRecord.attendance_date >= from_date,
                AttendanceRecord.attendance_date <= to_date,
            )
            .order_by(AttendanceRecord.attendance_date, User.first_name)
            .all()
        )

        # Build CSV
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Date", "Employee Code", "Employee Name", "Status", "Check In", "Check Out", "Face Score", "Distance (m)"])
        for record, user in records:
            writer.writerow([
                record.attendance_date.isoformat(),
                user.employee_code,
                user.full_name,
                record.status,
                record.check_in_time.strftime("%H:%M") if record.check_in_time else "",
                record.check_out_time.strftime("%H:%M") if record.check_out_time else "",
                f"{record.face_score:.3f}" if record.face_score else "",
                round(record.location_distance_meters or 0),
            ])

        # Upload to S3
        s3 = boto3.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT,
            aws_access_key_id=settings.S3_ACCESS_KEY,
            aws_secret_access_key=settings.S3_SECRET_KEY,
            region_name=settings.S3_REGION,
        )
        key = f"reports/{org_id}/attendance_{date_from}_{date_to}_{self.request.id}.csv"
        s3.put_object(Bucket=settings.S3_BUCKET, Key=key, Body=output.getvalue().encode(), ContentType="text/csv")
        url = s3.generate_presigned_url("get_object", Params={"Bucket": settings.S3_BUCKET, "Key": key},
                                         ExpiresIn=settings.S3_PRESIGNED_URL_EXPIRE_SECONDS)
        return {"download_url": url, "expires_in": settings.S3_PRESIGNED_URL_EXPIRE_SECONDS}

    except Exception as exc:
        raise self.retry(exc=exc, countdown=120, max_retries=2)
    finally:
        session.close()


@celery_app.task(name="app.workers.tasks.send_push_notification")
def send_push_notification(user_id: str, title: str, body: str, data: dict | None = None):
    """Send FCM push notification to a user's device (stub — extend with actual FCM call)."""
    from app.config import settings
    if not settings.FCM_PROJECT_ID:
        return {"status": "skipped", "reason": "FCM not configured"}
    # TODO: Implement with google-auth + FCM HTTP v1 API
    return {"status": "queued", "user_id": user_id}
