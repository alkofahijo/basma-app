from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import District, Government, Area
from ..schemas import (
    DistrictCreate, DistrictOut, DistrictUpdate,
    AreaOut
)

router = APIRouter(prefix="/districts", tags=["districts"])

@router.get("", response_model=List[DistrictOut])
def list_districts(db: Session = Depends(get_db)):
    rows = db.execute(select(District).order_by(District.id.asc())).scalars().all()
    return rows

@router.get("/{district_id}", response_model=DistrictOut)
def get_district(district_id: int, db: Session = Depends(get_db)):
    obj = db.get(District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.post("", response_model=DistrictOut, status_code=status.HTTP_201_CREATED)
def create_district(payload: DistrictCreate, db: Session = Depends(get_db)):
    # ensure parent exists
    if not db.get(Government, payload.government_id):
        raise HTTPException(400, "Invalid government_id")
    obj = District(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.patch("/{district_id}", response_model=DistrictOut)
def update_district(district_id: int, payload: DistrictUpdate, db: Session = Depends(get_db)):
    obj = db.get(District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    data = payload.model_dump(exclude_unset=True)
    # if changing parent
    if "government_id" in data and data["government_id"] is not None:
        if not db.get(Government, data["government_id"]):
            raise HTTPException(400, "Invalid government_id")
    for k, v in data.items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.delete("/{district_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_district(district_id: int, db: Session = Depends(get_db)):
    obj = db.get(District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Cannot delete: dependent areas exist")
    return None

# Nested: /districts/{id}/areas
@router.get("/{district_id}/areas", response_model=List[AreaOut])
def list_areas_of_district(district_id: int, db: Session = Depends(get_db)):
    if not db.get(District, district_id):
        raise HTTPException(404, "District not found")
    rows = db.execute(
        select(Area).where(Area.district_id == district_id).order_by(Area.id.asc())
    ).scalars().all()
    return rows
