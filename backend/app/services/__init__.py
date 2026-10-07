"""
FaceVault — Service layer __init__

Services:
- own business logic and transaction orchestration
- call repositories for database access
- do NOT return FastAPI response objects
- commit transactions (repositories do NOT commit)
"""
from __future__ import annotations
