"""Help desk — mobile ticket creation + admin management."""
from fastapi import APIRouter
from sqlalchemy import select

from app.core.exceptions import NotFoundError
from app.db.models.help_category import HelpCategory, HelpRequest
from app.db.models.help_comment import HelpComment
from app.dependencies import CurrentUser, DbSession
from app.schemas.domain import HelpCommentCreate, HelpCommentOut, HelpTicketCreate, HelpTicketOut
from app.utils.time import utcnow

router = APIRouter()

# ─── Mobile ───────────────────────────────────────────────────────────────────

@router.get("/help/categories", response_model=list[str], summary="Issue type list")
async def issue_types(user: CurrentUser, db: DbSession) -> list[str]:
    """Flutter HelpApi.issueTypes()."""
    result = await db.execute(
        select(HelpCategory).where(HelpCategory.organization_id == user.organization_id, HelpCategory.active == True)
    )
    cats = result.scalars().all()
    if cats:
        return [c.name for c in cats]
    # Fallback defaults
    return [
        "Location Error", "Face Recognition Failed", "GPS Problem", "Camera Problem",
        "App Error", "Internet / Sync Issue", "Wrong Assigned Location",
        "Permission Problem", "Attendance Missing", "Shift Timing Issue", "Device Changed", "Other",
    ]


@router.post("/help/tickets", response_model=HelpTicketOut, summary="Create help ticket")
async def create_ticket(body: HelpTicketCreate, user: CurrentUser, db: DbSession) -> HelpTicketOut:
    """Flutter HelpApi.createTicket()."""
    ticket = HelpRequest(
        organization_id=user.organization_id,
        user_id=user.id,
        issue_type=body.issue_type,
        description=body.description,
        device_terminal=body.device_terminal,
        status="OPEN",
        priority="NORMAL",
    )
    db.add(ticket)
    await db.flush()

    # System comment
    db.add(HelpComment(
        request_id=ticket.id,
        author_id=user.id,
        body=f"Ticket created: {body.issue_type}",
        is_system=True,
    ))
    await db.commit()
    await db.refresh(ticket)
    return _to_ticket_out(ticket, user.full_name, user.id)


@router.get("/help/tickets", response_model=list[HelpTicketOut], summary="My tickets")
async def my_tickets(user: CurrentUser, db: DbSession) -> list[HelpTicketOut]:
    """Flutter HelpApi.myTickets()."""
    result = await db.execute(
        select(HelpRequest).where(HelpRequest.user_id == user.id)
        .order_by(HelpRequest.created_at.desc()).limit(30)
    )
    tickets = result.scalars().all()
    return [_to_ticket_out(t, user.full_name, user.id) for t in tickets]


@router.get("/help/tickets/{ticket_id}", response_model=HelpTicketOut, summary="Ticket detail")
async def ticket_detail(ticket_id: str, user: CurrentUser, db: DbSession) -> HelpTicketOut:
    """Flutter HelpApi.detail(id)."""
    result = await db.execute(
        select(HelpRequest).where(
            HelpRequest.id == ticket_id,
            HelpRequest.organization_id == user.organization_id,
        )
    )
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise NotFoundError()
    return _to_ticket_out(ticket, user.full_name, user.id)


# ─── Admin ────────────────────────────────────────────────────────────────────

@router.get("/admin/help/tickets", response_model=list[HelpTicketOut], summary="All tickets (admin)")
async def admin_list_tickets(user: CurrentUser, db: DbSession) -> list[HelpTicketOut]:
    """Admin helpDeskApi.list()."""
    result = await db.execute(
        select(HelpRequest).where(HelpRequest.organization_id == user.organization_id)
        .order_by(HelpRequest.created_at.desc()).limit(100)
    )
    tickets = result.scalars().all()
    return [_to_ticket_out(t) for t in tickets]


@router.post("/admin/help/tickets/{ticket_id}/resolve", summary="Resolve ticket (admin)")
async def resolve_ticket(ticket_id: str, user: CurrentUser, db: DbSession) -> dict:
    """Admin helpDeskApi.resolve()."""
    result = await db.execute(
        select(HelpRequest).where(HelpRequest.id == ticket_id, HelpRequest.organization_id == user.organization_id)
    )
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise NotFoundError()
    ticket.status = "RESOLVED"
    db.add(HelpComment(request_id=ticket.id, author_id=user.id, body="Ticket resolved by admin.", is_system=True))
    await db.commit()
    return {"id": ticket_id, "status": "RESOLVED"}


@router.post("/admin/help/tickets/{ticket_id}/notes", summary="Add admin note")
async def add_note(ticket_id: str, body: HelpCommentCreate, user: CurrentUser, db: DbSession) -> dict:
    """Admin helpDeskApi.postNote()."""
    result = await db.execute(
        select(HelpRequest).where(HelpRequest.id == ticket_id, HelpRequest.organization_id == user.organization_id)
    )
    if not result.scalar_one_or_none():
        raise NotFoundError()
    db.add(HelpComment(request_id=ticket_id, author_id=user.id, body=body.body, is_internal=body.is_internal))
    await db.commit()
    return {"message": "Note added."}


def _to_ticket_out(
    ticket: HelpRequest,
    employee_name: str | None = None,
    employee_id: str | None = None,
) -> HelpTicketOut:
    return HelpTicketOut(
        id=ticket.id,
        issue_type=ticket.issue_type,
        description=ticket.description,
        status=ticket.status,
        priority=ticket.priority,
        created_at=ticket.created_at,
        employee_id=employee_id or ticket.user_id,
        employee_name=employee_name,
        device_terminal=ticket.device_terminal,
    )
