# app/routers/admin_users.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_admin_user
from ..models import User
from ..auth_utils import hash_password
from ..schemas_admin import (
    AdminUserCreate,
    AdminUserUpdate,
    AdminUserOut,
)

router = APIRouter(
    prefix="/admin/users",
    tags=["Admin Users"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[AdminUserOut])
def list_users(
    db: Session = Depends(get_db),
    q: str | None = Query(None, description="بحث بالاسم"),
):
    query = db.query(User)
    if q:
        query = query.filter(User.username.like(f"%{q}%"))
    users = query.order_by(User.id.desc()).all()
    return users


@router.post("/", response_model=AdminUserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    data: AdminUserCreate,
    db: Session = Depends(get_db),
):
    # check username uniqueness
    exists = db.query(User).filter(User.username == data.username).first()
    if exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="اسم المستخدم مستخدم من قبل",
        )

    user = User(
        username=data.username,
        hashed_password=hash_password(data.password),
        user_type=data.user_type,
        is_active=data.is_active,
        account_id=data.account_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=AdminUserOut)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    return user


@router.put("/{user_id}", response_model=AdminUserOut)
def update_user(
    user_id: int,
    data: AdminUserUpdate,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")

    if data.username:
        # check duplicate
        exists = (
            db.query(User)
            .filter(User.username == data.username, User.id != user_id)
            .first()
        )
        if exists:
            raise HTTPException(
                status_code=400,
                detail="اسم المستخدم مستخدم من قبل",
            )
        user.username = data.username

    if data.password:
        user.hashed_password = hash_password(data.password)
    if data.is_active is not None:
        user.is_active = data.is_active
    if data.user_type is not None:
        user.user_type = data.user_type
    if data.account_id is not None:
        user.account_id = data.account_id

    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    db.delete(user)
    db.commit()
    return
