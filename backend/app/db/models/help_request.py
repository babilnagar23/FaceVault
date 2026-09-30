import uuid
from sqlalchemy import String, Boolean, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, TimestampMixin

# This file is kept for import symmetry.
# The real HelpRequest class is defined in help_category.py alongside HelpCategory.
# Re-export it here so existing code that imports from help_request still works.
from app.db.models.help_category import HelpRequest  # noqa: F401

__all__ = ["HelpRequest"]
