import uuid
from sqlalchemy import String, ForeignKey, JSON, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, TimestampMixin


class AuditLog(Base, TimestampMixin):
    """
    Immutable audit trail for all sensitive operations.
    Records are NEVER deleted. NEVER log passwords, tokens, or embeddings.
    """
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_org_created", "organization_id", "created_at"),
        Index("ix_audit_actor", "actor_id"),
        Index("ix_audit_entity", "entity_type", "entity_id"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    organization_id: Mapped[str] = mapped_column(String(36), ForeignKey("organizations.id"), nullable=False, index=True)
    actor_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"))  # None = system
    actor_label: Mapped[str | None] = mapped_column(String(255))  # Display name snapshot

    action: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    entity_type: Mapped[str | None] = mapped_column(String(50))
    entity_id: Mapped[str | None] = mapped_column(String(36))

    before_data: Mapped[dict | None] = mapped_column(JSON)
    after_data: Mapped[dict | None] = mapped_column(JSON)

    ip_address: Mapped[str | None] = mapped_column(String(45))
    user_agent: Mapped[str | None] = mapped_column(Text)
    device_id: Mapped[str | None] = mapped_column(String(36))
    details: Mapped[str | None] = mapped_column(Text)
