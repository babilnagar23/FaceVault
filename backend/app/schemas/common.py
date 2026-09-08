"""Common Pydantic schemas shared across the API."""
from datetime import datetime
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    """Standard success envelope."""
    data: T
    message: str = "OK"


class ErrorDetail(BaseModel):
    code: str
    message: str
    details: dict[str, Any] = {}


class OrmModel(BaseModel):
    """Base schema for ORM-mapped models."""
    model_config = ConfigDict(from_attributes=True)
