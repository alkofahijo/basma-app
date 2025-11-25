from __future__ import annotations

from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.auth_utils import hash_password
from app.schemas_admin import (
    AdminUserCreate,
    AdminUserUpdate,
    AdminUserOut,
)


def list_users(db: Session = Depends(get_db), q: str | None = None) -> list[AdminUserOut]:
    query = db.query(models.User)
    if q:
        query = query.filter(models.User.username.like(f"%{q}%"))
    users = query.order_by(models.User.id.desc()).all()
    return users


def create_user(data: AdminUserCreate, db: Session = Depends(get_db)) -> AdminUserOut:
    exists = db.query(models.User).filter(models.User.username == data.username).first()
    if exists:
        raise HTTPException(
            status_code=400,
            detail="اسم المستخدم مستخدم من قبل",
        )

    user = models.User(
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


def get_user(user_id: int, db: Session = Depends(get_db)) -> AdminUserOut:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    return user


def update_user(user_id: int, data: AdminUserUpdate, db: Session = Depends(get_db)) -> AdminUserOut:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")

    if data.username:
        exists = (
            db.query(models.User)
            .filter(models.User.username == data.username, models.User.id != user_id)
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


def delete_user(user_id: int, db: Session = Depends(get_db)) -> None:
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="المستخدم غير موجود")
    db.delete(user)
    db.commit()
    return None
