"""Projects and Shifts routers."""
from fastapi import APIRouter
from sqlalchemy import select

from app.db.models.project import Project
from app.db.models.shift import Shift
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import ProjectCreate, ProjectOut, ShiftCreate, ShiftOut

# ─── Projects ─────────────────────────────────────────────────────────────────
router = APIRouter()


@router.get("/projects", response_model=list[ProjectOut], summary="List projects")
async def list_projects(user: CurrentUser, db: DbSession) -> list[ProjectOut]:
    result = await db.execute(
        select(Project).where(Project.organization_id == user.organization_id, Project.active == True)
        .order_by(Project.name)
    )
    return [ProjectOut(id=p.id, name=p.name, code=p.code, description=p.description, active=p.active)
            for p in result.scalars().all()]


@router.post("/admin/projects", response_model=ProjectOut, summary="Create project (admin)")
async def create_project(body: ProjectCreate, user: CurrentUser, db: DbSession) -> ProjectOut:
    proj = Project(organization_id=user.organization_id, name=body.name, code=body.code, description=body.description)
    db.add(proj)
    await db.commit()
    await db.refresh(proj)
    return ProjectOut(id=proj.id, name=proj.name, code=proj.code, description=proj.description, active=proj.active)
