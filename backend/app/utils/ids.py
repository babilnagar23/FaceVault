"""Prefixed UUID generation for human-readable IDs (EMP-xxx, ATT-xxx, etc.)"""
import uuid


def new_uuid() -> str:
    return str(uuid.uuid4())


def new_id(prefix: str = "") -> str:
    """Generate a short prefixed ID like EMP-a3f2, ATT-9d12."""
    short = uuid.uuid4().hex[:8].upper()
    return f"{prefix}-{short}" if prefix else short
