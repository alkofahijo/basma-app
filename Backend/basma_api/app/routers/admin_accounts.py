# app/routers/admin_accounts.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_admin_user
from ..models import Account, User
from ..auth_utils import hash_password
from ..schemas_admin import (
    AdminAccountCreate,
    AdminAccountUpdate,
    AdminAccountOut,
)

router = APIRouter(
    prefix="/admin/accounts",
    tags=["Admin Accounts"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[AdminAccountOut])
def list_accounts(
    db: Session = Depends(get_db),
    account_type_id: int | None = Query(None),
    q: str | None = Query(None, description="بحث بالاسم"),
):
    query = db.query(Account)

    if account_type_id is not None:
        query = query.filter(Account.account_type_id == account_type_id)
    if q:
        query = query.filter(Account.name_ar.like(f"%{q}%"))

    accounts = query.order_by(Account.id.desc()).all()
    return accounts


@router.post("/", response_model=AdminAccountOut, status_code=status.HTTP_201_CREATED)
def create_account(
    data: AdminAccountCreate,
    db: Session = Depends(get_db),
):
    # check mobile uniqueness
    exists = db.query(Account).filter(Account.mobile_number == data.mobile_number).first()
    if exists:
        raise HTTPException(
            status_code=400,
            detail="رقم الجوال مستخدم من قبل",
        )

    account = Account(
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
    db.flush()  # get id without commit yet

    if data.username and data.password:
        # create user linked to this account
        user = User(
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


@router.get("/{account_id}", response_model=AdminAccountOut)
def get_account(
    account_id: int,
    db: Session = Depends(get_db),
):
    account = db.query(Account).filter(Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")
    return account


@router.put("/{account_id}", response_model=AdminAccountOut)
def update_account(
    account_id: int,
    data: AdminAccountUpdate,
    db: Session = Depends(get_db),
):
    account = db.query(Account).filter(Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")

    if data.mobile_number:
        exists = (
            db.query(Account)
            .filter(Account.mobile_number == data.mobile_number, Account.id != account_id)
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


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: int,
    db: Session = Depends(get_db),
):
    account = db.query(Account).filter(Account.id == account_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="الحساب غير موجود")
    db.delete(account)
    db.commit()
    return
