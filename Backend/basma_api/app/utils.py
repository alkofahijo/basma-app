from __future__ import annotations
from datetime import datetime
import random

def generate_report_code(prefix: str = "UF") -> str:
    now = datetime.now()
    # UF-2026-11-06-2003
    tail = random.randint(1000, 9999)
    return f"{prefix}-{now.year:04d}-{now.month:02d}-{now.day:02d}-{tail}"
