"""
FaceVault — Repository layer __init__

Repositories:
- contain database query/persistence logic only
- do NOT contain HTTP concerns or permission decisions
- do NOT silently commit transactions (caller commits)
- ALWAYS scope tenant-sensitive queries by organization_id
"""
from __future__ import annotations
