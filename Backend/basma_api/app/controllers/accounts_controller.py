from __future__ import annotations

from typing import List, Optional

from fastapi import HTTPException, Depends, status
from sqlalchemy import select, or_, func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from ..db import get_db
from ..models import Account, AccountType, Government, User, Report
from ..security import hash_password


def list_account_types(db: Session = Depends(get_db)) -> List[AccountType]:
    stmt = select(AccountType).order_by(AccountType.id.asc())
    rows = db.execute(stmt).scalars().all()
    return rows


def list_accounts(
    db: Session = Depends(get_db),
    account_type_id: Optional[int] = None,
    government_id: Optional[int] = None,
    is_active: Optional[int] = None,
    q: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> List[Account]:
    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
    )

    if account_type_id is not None:
        stmt = stmt.where(Account.account_type_id == account_type_id)

    if government_id is not None:
        stmt = stmt.where(Account.government_id == government_id)

    if is_active is not None:
        stmt = stmt.where(Account.is_active == is_active)

    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(
                Account.name_ar.like(like),
                Account.name_en.like(like),
                Account.mobile_number.like(like),
            )
        )

    stmt = stmt.order_by(Account.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).scalars().all()

    return rows


def list_accounts_paged(
    db: Session = Depends(get_db),
    account_type_id: Optional[int] = None,
    government_id: Optional[int] = None,
    is_active: Optional[int] = None,
    q: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
):
    base_stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
    )

    if account_type_id is not None:
        base_stmt = base_stmt.where(Account.account_type_id == account_type_id)

    if government_id is not None:
        base_stmt = base_stmt.where(Account.government_id == government_id)

    if is_active is not None:
        base_stmt = base_stmt.where(Account.is_active == is_active)

    if q:
        like = f"%{q}%"
        base_stmt = base_stmt.where(
            or_(
                Account.name_ar.like(like),
                Account.name_en.like(like),
                Account.mobile_number.like(like),
            )
        )

    total_stmt = select(func.count(Account.id))
    for crit in base_stmt._where_criteria:  # type: ignore[attr-defined]
        total_stmt = total_stmt.where(crit)

    total = db.execute(total_stmt).scalar_one()

    offset = (page - 1) * page_size

    stmt = (
        base_stmt
        .order_by(Account.id.desc())
        .limit(page_size)
        .offset(offset)
    )

    items = db.execute(stmt).scalars().all()

    return {
        "total": total,
        "page": page,
        "page_size": page_size,
        "items": items,
    }


def get_account(account_id: int, db: Session = Depends(get_db)) -> Account:
    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account_id)
    )
    account = db.execute(stmt).scalars().first()

    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    return account


def create_account(payload, db: Session = Depends(get_db)) -> Account:
    if not db.get(Government, payload.government_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid government_id",
        )

    if not db.get(AccountType, payload.account_type_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid account_type_id",
        )

    if db.scalar(select(Account).where(Account.mobile_number == payload.mobile_number)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        )

    account = Account(
        account_type_id=payload.account_type_id,
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        government_id=payload.government_id,
        logo_url=payload.logo_url,
        join_form_link=payload.join_form_link,
    )
    db.add(account)

    try:
        db.flush()
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        ) from e

    if getattr(payload, "username", None) and getattr(payload, "password", None):
        if db.scalar(select(User).where(User.username == payload.username)):
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists",
            )

        user = User(
            username=payload.username,
            hashed_password=hash_password(payload.password),
            user_type=2,
            account_id=account.id,
        )
        db.add(user)
        try:
            db.flush()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists",
            ) from e

    db.commit()

    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account.id)
    )
    account_with_rels = db.execute(stmt).scalars().first()

    return account_with_rels or account


def update_account(account_id: int, payload, db: Session = Depends(get_db)):
    account = db.get(Account, account_id)
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    data = payload.model_dump(exclude_unset=True)

    if "account_type_id" in data and data["account_type_id"] is not None:
        if not db.get(AccountType, data["account_type_id"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid account_type_id",
            )
        account.account_type_id = data["account_type_id"]

    if "government_id" in data and data["government_id"] is not None:
        if not db.get(Government, data["government_id"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid government_id",
            )
        account.government_id = data["government_id"]

    for field in [
        "name_ar",
        "name_en",
        "mobile_number",
        "logo_url",
        "is_active",
        "show_details",
        "reports_completed_count",
        "join_form_link",
    ]:
        if field in data:
            setattr(account, field, data[field])

    if "username" in data or "password" in data:
        user = db.scalar(select(User).where(User.account_id == account.id))

        if user:
            if data.get("username"):
                if db.scalar(
                    select(User).where(
                        User.username == data["username"],
                        User.id != user.id,
                    )
                ):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    )
                user.username = data["username"]

            if data.get("password"):
                user.hashed_password = hash_password(data["password"])

            db.add(user)
            try:
                db.flush()
            except IntegrityError as e:
                db.rollback()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists",
                ) from e

        else:
            if data.get("username") and data.get("password"):
                if db.scalar(
                    select(User).where(User.username == data["username"])
                ):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    )

                new_user = User(
                    username=data["username"],
                    hashed_password=hash_password(data["password"]),
                    user_type=2,
                    account_id=account.id,
                )
                db.add(new_user)
                try:
                    db.flush()
                except IntegrityError as e:
                    db.rollback()
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    ) from e
            elif data.get("username") or data.get("password"):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Both username and password are required to create a linked user",
                )

    try:
        db.commit()
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        ) from e

    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account.id)
    )
    updated_account = db.execute(stmt).scalars().first()

    return updated_account or account


def delete_account(account_id: int, db: Session = Depends(get_db), hard: bool = False):
    account = db.get(Account, account_id)
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    if hard:
        users = db.execute(
            select(User).where(User.account_id == account.id)
        ).scalars().all()
        for u in users:
            u.account_id = None
            db.add(u)

        reports = db.execute(
            select(Report).where(Report.adopted_by_account_id == account.id)
        ).scalars().all()
        for r in reports:
            r.adopted_by_account_id = None
            db.add(r)

        db.delete(account)

    else:
        account.is_active = 0
        db.add(account)

        users = db.execute(
            select(User).where(User.account_id == account.id)
        ).scalars().all()
        for u in users:
            u.is_active = 0
            db.add(u)

    db.commit()
    return None
