"""Biometric enrollment endpoints — no raw embeddings exposed."""
from fastapi import APIRouter
from sqlalchemy import select

from app.core.constants import BiometricStatus
from app.db.models.face_enrollment import FaceEnrollment
from app.db.models.user import User
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import BiometricStatusOut, EnrollmentCompleteRequest
from app.utils.time import utcnow

router = APIRouter()


@router.get("/status", response_model=BiometricStatusOut, summary="Biometric enrollment status")
async def biometric_status(user: CurrentUser, db: DbSession) -> BiometricStatusOut:
    """Flutter FaceEnrollmentApi.isEnrolled()."""
    result = await db.execute(select(FaceEnrollment).where(FaceEnrollment.user_id == user.id))
    enrollment = result.scalar_one_or_none()
    if not enrollment:
        return BiometricStatusOut(enrolled=False, status=BiometricStatus.NOT_ENROLLED)
    return BiometricStatusOut(
        enrolled=enrollment.status == BiometricStatus.ENROLLED,
        status=enrollment.status,
        model_version=enrollment.model_version,
        quality_score=enrollment.quality_score,
        enrolled_at=enrollment.enrolled_at,
    )


@router.post("/enroll/start", summary="Start face enrollment")
async def start_enrollment(user: CurrentUser, db: DbSession) -> dict:
    """Flutter FaceEnrollmentApi.startEnrollment()."""
    result = await db.execute(select(FaceEnrollment).where(FaceEnrollment.user_id == user.id))
    enrollment = result.scalar_one_or_none()
    if not enrollment:
        enrollment = FaceEnrollment(
            user_id=user.id,
            organization_id=user.organization_id,
            status=BiometricStatus.PENDING,
        )
        db.add(enrollment)
    else:
        enrollment.status = BiometricStatus.PENDING
    await db.commit()
    return {"status": BiometricStatus.PENDING, "message": "Enrollment started. Capture face frames on device."}


@router.post("/enroll/complete", summary="Complete face enrollment")
async def complete_enrollment(
    body: EnrollmentCompleteRequest, user: CurrentUser, db: DbSession
) -> BiometricStatusOut:
    """Flutter FaceEnrollmentApi.completeEnrollment() — called after on-device embedding generation."""
    result = await db.execute(select(FaceEnrollment).where(FaceEnrollment.user_id == user.id))
    enrollment = result.scalar_one_or_none()
    if not enrollment:
        enrollment = FaceEnrollment(user_id=user.id, organization_id=user.organization_id)
        db.add(enrollment)

    enrollment.status = BiometricStatus.ENROLLED
    enrollment.model_version = body.model_version
    enrollment.quality_score = body.quality_score
    enrollment.liveness_score = body.liveness_score
    enrollment.enrolled_at = utcnow()
    enrollment.last_updated_at = utcnow()

    # Update user flag
    user_obj = await db.get(User, user.id)
    if user_obj:
        user_obj.face_enrolled = True

    await db.commit()
    await db.refresh(enrollment)
    return BiometricStatusOut(
        enrolled=True,
        status=enrollment.status,
        model_version=enrollment.model_version,
        quality_score=enrollment.quality_score,
        enrolled_at=enrollment.enrolled_at,
    )


@router.post("/admin/{employee_id}/reset", summary="Admin: trigger face re-enrollment")
async def admin_reset_biometrics(employee_id: str, user: CurrentUser, db: DbSession) -> dict:
    result = await db.execute(
        select(FaceEnrollment).where(
            FaceEnrollment.user_id == employee_id,
        )
    )
    enrollment = result.scalar_one_or_none()
    if enrollment:
        enrollment.status = BiometricStatus.RE_ENROLL_REQUIRED
        enrollment.last_updated_at = utcnow()
    emp = await db.get(User, employee_id)
    if emp:
        emp.face_enrolled = False
    await db.commit()
    return {"message": "Re-enrollment required for this employee."}
