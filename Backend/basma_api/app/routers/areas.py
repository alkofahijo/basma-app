from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Area, District, Location
from ..schemas import AreaCreate, AreaOut, AreaUpdate, LocationOut

router = APIRouter(prefix="/areas", tags=["areas"])

@router.get("", response_model=List[AreaOut])
def list_areas(db: Session = Depends(get_db)):
    rows = db.execute(select(Area).order_by(Area.id.asc())).scalars().all()
    return rows

@router.get("/{area_id}", response_model=AreaOut)
def get_area(area_id: int, db: Session = Depends(get_db)):
    obj = db.get(Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.post("", response_model=AreaOut, status_code=status.HTTP_201_CREATED)
def create_area(payload: AreaCreate, db: Session = Depends(get_db)):
    if not db.get(District, payload.district_id):
        raise HTTPException(400, "Invalid district_id")
    obj = Area(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.patch("/{area_id}", response_model=AreaOut)
def update_area(area_id: int, payload: AreaUpdate, db: Session = Depends(get_db)):
    obj = db.get(Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    data = payload.model_dump(exclude_unset=True)
    if "district_id" in data and data["district_id"] is not None:
        if not db.get(District, data["district_id"]):
            raise HTTPException(400, "Invalid district_id")
    for k, v in data.items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.delete("/{area_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_area(area_id: int, db: Session = Depends(get_db)):
    obj = db.get(Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Cannot delete: dependent locations exist")
    return None

# Nested: /areas/{id}/locations
@router.get("/{area_id}/locations", response_model=List[LocationOut])
def list_locations_of_area(area_id: int, db: Session = Depends(get_db)):
    if not db.get(Area, area_id):
        raise HTTPException(404, "Area not found")
    rows = db.execute(
        select(Location).where(Location.area_id == area_id).order_by(Location.id.asc())
    ).scalars().all()
    return rows
