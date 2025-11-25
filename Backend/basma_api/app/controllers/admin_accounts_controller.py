from __future__ import annotations

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.auth_utils import hash_password
from app.schemas_admin import (
    AdminAccountCreate,
    AdminAccountUpdate,
    AdminAccountOut,
)


def list_accounts(
    db: Session = Depends(get_db),
    account_type_id: int | None = None,
    q: str | None = None,
) -> list[AdminAccountOut]:
    query = db.query(models.Account)

    if account_type_id is not None:
        query = query.filter(models.Account.account_type_id == account_type_id)
    if q:
        query = query.filter(models.Account.name_ar.like(f"%{q}%"))

    accounts = query.order_by(models.Account.id.desc()).all()
    return accounts


def create_account(data: AdminAccountCreate, db: Session = Depends(get_db)) -> AdminAccountOut:
    exists = db.query(models.Account).filter(models.Account.mobile_number == data.mobile_number).first()
    if exists:
        raise HTTPException(
            status_code=400,
            detail="رقم الجوال مستخدم من قبل",
        )

    account = models.Account(
        account_type_id=data.account_type_id,
        name_ar=data.name_ar,
        name_en=data.name_en,
        mobile_number=data.mobile_number,
        government_id=data.government_id,
        logo_url=data.logo_url,
        join_form_link=data.join_form_link,
        is_active=data.is_active,
        show_details=data.show_details,
    )
    db.add(account)
    db.flush()

    if data.username and data.password:
        user = models.User(
            username=data.username,
            hashed_password=hash_password(data.password),
            user_type=2,
            is_active=1,
            account_id=account.id,
        )
        db.add(user)

    db.commit()
    db.refresh(account)
    return account


def get_account(account_id: int, db: Session = Depends(get_db)) -> AdminAccountOut:
    account = db.query(models.Account).filter(models.Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")
    return account


def update_account(account_id: int, data: AdminAccountUpdate, db: Session = Depends(get_db)) -> AdminAccountOut:
    account = db.query(models.Account).filter(models.Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")

    if data.mobile_number:
        exists = (
            db.query(models.Account)
            .filter(models.Account.mobile_number == data.mobile_number, models.Account.id != account_id)
            .first()
        )
        if exists:
            raise HTTPException(status_code=400, detail="رقم الجوال مستخدم من قبل")
        account.mobile_number = data.mobile_number

    for field in [
        "account_type_id",
        "name_ar",
        "name_en",
        "government_id",
        "logo_url",
        "join_form_link",
        "is_active",
        "show_details",
    ]:
        value = getattr(data, field)
        if value is not None:
            setattr(account, field, value)

    db.commit()
    db.refresh(account)
    return account


def delete_account(account_id: int, db: Session = Depends(get_db)) -> None:
    account = db.query(models.Account).filter(models.Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")
    db.delete(account)
    db.commit()
    return None
