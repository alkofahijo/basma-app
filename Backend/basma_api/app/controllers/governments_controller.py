from __future__ import annotations

from typing import List

from fastapi import Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.schemas import (
    GovernmentCreate, GovernmentOut, GovernmentUpdate,
    DistrictOut
)


def list_governments(db: Session = Depends(get_db)) -> List[GovernmentOut]:
    rows = db.execute(select(models.Government).order_by(models.Government.id.asc())).scalars().all()
    return rows


def get_government(government_id: int, db: Session = Depends(get_db)) -> GovernmentOut:
    obj = db.get(models.Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj


def create_government(payload: GovernmentCreate, db: Session = Depends(get_db)) -> GovernmentOut:
    obj = models.Government(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def update_government(government_id: int, payload: GovernmentUpdate, db: Session = Depends(get_db)) -> GovernmentOut:
    obj = db.get(models.Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def delete_government(government_id: int, db: Session = Depends(get_db)) -> None:
    obj = db.get(models.Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Cannot delete: dependent districts exist")
    return None


def list_districts_of_government(government_id: int, db: Session = Depends(get_db)) -> List[DistrictOut]:
    if not db.get(models.Government, government_id):
        raise HTTPException(404, "Government not found")
    rows = db.execute(
        select(models.District).where(models.District.government_id == government_id).order_by(models.District.id.asc())
    ).scalars().all()
    return rows
