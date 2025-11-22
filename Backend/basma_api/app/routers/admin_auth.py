# app/routers/admin_auth.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..deps import get_db
from ..models import User
from ..auth_utils import verify_password, create_access_token
from ..schemas_admin import AdminLoginRequest, TokenOut

router = APIRouter(
    prefix="/admin",
    tags=["Admin Auth"],
)


@router.post("/login", response_model=TokenOut)
def admin_login(
    data: AdminLoginRequest,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.username == data.username)
        .first()
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
        )

    if not verify_password(data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
        )

    # must be admin
    if user.user_type != 1 or user.account_id is not None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليست لديك صلاحية الدخول إلى لوحة التحكم",
        )

    token = create_access_token(
        sub=str(user.id),
        user_type=user.user_type,
        account_id=user.account_id,
    )
    return TokenOut(access_token=token)
