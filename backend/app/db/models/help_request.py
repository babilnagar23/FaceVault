import uuid
from sqlalchemy import String, Boolean, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin


class HelpRequest(Base, TimestampMixin):
    """Stub for cross-model relationship import."""
    pass  # Defined in help_category.py — this file kept for import symmetry
