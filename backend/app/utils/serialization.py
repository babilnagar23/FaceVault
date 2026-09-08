"""JSON serialization helpers."""
from datetime import date, datetime
from decimal import Decimal
from typing import Any
import json


class FaceVaultJSONEncoder(json.JSONEncoder):
    def default(self, obj: Any) -> Any:
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, date):
            return obj.isoformat()
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def to_json(obj: Any) -> str:
    return json.dumps(obj, cls=FaceVaultJSONEncoder)
