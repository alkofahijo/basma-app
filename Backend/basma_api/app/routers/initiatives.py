from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Initiative, Government, User
from ..schemas import InitiativeCreate, InitiativeOut
from ..security import hash_password

router = APIRouter(prefix="/initiatives", tags=["initiatives"])


# ---- Local Update schema (kept here so you don't have to edit schemas.py)
class InitiativeUpdate(BaseModel):
    name_ar: Optional[str] = None
    name_en: Optional[str] = None
    mobile_number: Optional[str] = None
    join_form_link: Optional[str] = None
    government_id: Optional[int] = None
    logo_url: Optional[str] = None
    members_count: Optional[int] = None
    reports_completed_count: Optional[int] = None
    is_active: Optional[int] = None

    # Optional user updates (if this initiative has/needs a linked account)
    username: Optional[str] = None
    password: Optional[str] = None


@router.get("", response_model=List[InitiativeOut])
def list_initiatives(
    db: Session = Depends(get_db),
    government_id: Optional[int] = Query(None),
    is_active: Optional[int] = Query(None, description="1 or 0"),
    q: Optional[str] = Query(None, description="search name_ar/name_en/mobile"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    stmt = select(Initiative)

    if government_id is not None:
        stmt = stmt.where(Initiative.government_id == government_id)

    if is_active is not None:
        stmt = stmt.where(Initiative.is_active == is_active)

    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(Initiative.name_ar.like(like), Initiative.name_en.like(like), Initiative.mobile_number.like(like))
        )

    stmt = stmt.order_by(Initiative.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).scalars().all()
    return rows


@router.get("/{initiative_id}", response_model=InitiativeOut)
def get_initiative(initiative_id: int, db: Session = Depends(get_db)):
    obj = db.get(Initiative, initiative_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Initiative not found")
    return obj


@router.post("", response_model=InitiativeOut, status_code=status.HTTP_201_CREATED)
def create_initiative(payload: InitiativeCreate, db: Session = Depends(get_db)):
    # Validate parent government
    if not db.get(Government, payload.government_id):
        raise HTTPException(status_code=400, detail="Invalid government_id")

    # Create initiative
    initv = Initiative(
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        join_form_link=payload.join_form_link,
        government_id=payload.government_id,
        logo_url=payload.logo_url,
    )
    db.add(initv)
    try:
        db.flush()  # get initv.id
    except IntegrityError as e:
        db.rollback()
        # likely unique mobile violation
        raise HTTPException(status_code=400, detail="Mobile number already exists") from e

    # Create linked user (user_type = 2) if username/password provided
    if payload.username and payload.password:
        user = User(
            username=payload.username,
            hashed_password=hash_password(payload.password),
            user_type=2,
            initiative_id=initv.id,
        )
        db.add(user)
        try:
            db.flush()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(status_code=400, detail="Username already exists") from e

    db.commit()
    db.refresh(initv)
    return initv


@router.patch("/{initiative_id}", response_model=InitiativeOut)
def update_initiative(initiative_id: int, payload: InitiativeUpdate, db: Session = Depends(get_db)):
    obj = db.get(Initiative, initiative_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Initiative not found")

    data = payload.model_dump(exclude_unset=True)

    # Validate government_id if present
    if "government_id" in data and data["government_id"] is not None:
        if not db.get(Government, data["government_id"]):
            raise HTTPException(status_code=400, detail="Invalid government_id")

    # Update initiative fields
    for field in [
        "name_ar",
        "name_en",
        "mobile_number",
        "join_form_link",
        "government_id",
        "logo_url",
        "members_count",
        "reports_completed_count",
        "is_active",
    ]:
        if field in data:
            setattr(obj, field, data[field])

    # Handle linked user create/update if username/password provided
    if "username" in data or "password" in data:
        # Find existing linked user (if any)
        user = db.scalar(select(User).where(User.initiative_id == obj.id))
        if user:
            # Update existing user
            if "username" in data and data["username"]:
                user.username = data["username"]
            if "password" in data and data["password"]:
                user.hashed_password = hash_password(data["password"])
            db.add(user)
            try:
                db.flush()
            except IntegrityError as e:
                db.rollback()
                raise HTTPException(status_code=400, detail="Username already exists") from e
        else:
            # Create new user if both provided
            if data.get("username") and data.get("password"):
                user = User(
                    username=data["username"],
                    hashed_password=hash_password(data["password"]),
                    user_type=2,
                    initiative_id=obj.id,
                )
                db.add(user)
                try:
                    db.flush()
                except IntegrityError as e:
                    db.rollback()
                    raise HTTPException(status_code=400, detail="Username already exists") from e
            elif data.get("username") or data.get("password"):
                raise HTTPException(
                    status_code=400,
                    detail="Both username and password are required to create a linked user",
                )

    # Save all changes
    try:
        db.commit()
    except IntegrityError as e:
        db.rollback()
        # likely mobile unique violation
        raise HTTPException(status_code=400, detail="Mobile number already exists") from e

    db.refresh(obj)
    return obj


@router.delete("/{initiative_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_initiative(
    initiative_id: int,
    db: Session = Depends(get_db),
    hard: bool = Query(False, description="Set true to hard-delete (dangerous)"),
):
    obj = db.get(Initiative, initiative_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Initiative not found")

    if hard:
        # Caution: may fail if there are FK references; adjust to your policy.
        # Unlink user(s) first
        users = db.execute(select(User).where(User.initiative_id == obj.id)).scalars().all()
        for u in users:
            u.initiative_id = None
            db.add(u)
        db.delete(obj)
    else:
        # Soft-delete: mark as inactive
        obj.is_active = 0
        db.add(obj)

    db.commit()
    return None
