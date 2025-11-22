# app/deps.py
from __future__ import annotations

from typing import Dict, Any

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from .db import get_db
from .auth_utils import get_current_user_payload
from .models import User


def get_current_admin_user(
    payload: Dict[str, Any] = Depends(get_current_user_payload),
    db: Session = Depends(get_db),
) -> User:
    """
    Ensure the current JWT belongs to an admin:
    - user_type = 1
    - account_id is NULL
    - is_active = 1
    """
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or user.user_type != 1 or user.account_id is not None or user.is_active != 1:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized as admin",
        )

    return user
