from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Government, District
from ..schemas import (
    GovernmentCreate, GovernmentOut, GovernmentUpdate,
    DistrictOut
)

router = APIRouter(prefix="/governments", tags=["governments"])

@router.get("", response_model=List[GovernmentOut])
def list_governments(db: Session = Depends(get_db)):
    rows = db.execute(select(Government).order_by(Government.id.asc())).scalars().all()
    return rows

@router.get("/{government_id}", response_model=GovernmentOut)
def get_government(government_id: int, db: Session = Depends(get_db)):
    obj = db.get(Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.post("", response_model=GovernmentOut, status_code=status.HTTP_201_CREATED)
def create_government(payload: GovernmentCreate, db: Session = Depends(get_db)):
    obj = Government(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.patch("/{government_id}", response_model=GovernmentOut)
def update_government(government_id: int, payload: GovernmentUpdate, db: Session = Depends(get_db)):
    obj = db.get(Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.delete("/{government_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_government(government_id: int, db: Session = Depends(get_db)):
    obj = db.get(Government, government_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        # RESTRICT will cause an IntegrityError if children exist
        raise HTTPException(409, "Cannot delete: dependent districts exist")
    return None

# Nested: /governments/{id}/districts
@router.get("/{government_id}/districts", response_model=List[DistrictOut])
def list_districts_of_government(government_id: int, db: Session = Depends(get_db)):
    if not db.get(Government, government_id):
        raise HTTPException(404, "Government not found")
    rows = db.execute(
        select(District).where(District.government_id == government_id).order_by(District.id.asc())
    ).scalars().all()
    return rows
