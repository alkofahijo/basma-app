from __future__ import annotations

from typing import List

from fastapi import Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.schemas import (
    DistrictCreate, DistrictOut, DistrictUpdate,
    AreaOut
)


def list_districts(db: Session = Depends(get_db)) -> List[DistrictOut]:
    rows = db.execute(select(models.District).order_by(models.District.id.asc())).scalars().all()
    return rows


def get_district(district_id: int, db: Session = Depends(get_db)) -> DistrictOut:
    obj = db.get(models.District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj


def create_district(payload: DistrictCreate, db: Session = Depends(get_db)) -> DistrictOut:
    if not db.get(models.Government, payload.government_id):
        raise HTTPException(400, "Invalid government_id")
    obj = models.District(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def update_district(district_id: int, payload: DistrictUpdate, db: Session = Depends(get_db)) -> DistrictOut:
    obj = db.get(models.District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    data = payload.model_dump(exclude_unset=True)
    if "government_id" in data and data["government_id"] is not None:
        if not db.get(models.Government, data["government_id"]):
            raise HTTPException(400, "Invalid government_id")
    for k, v in data.items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def delete_district(district_id: int, db: Session = Depends(get_db)) -> None:
    obj = db.get(models.District, district_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Cannot delete: dependent areas exist")
    return None


def list_areas_of_district(district_id: int, db: Session = Depends(get_db)) -> List[AreaOut]:
    if not db.get(models.District, district_id):
        raise HTTPException(404, "District not found")
    rows = db.execute(
        select(models.Area).where(models.Area.district_id == district_id).order_by(models.Area.id.asc())
    ).scalars().all()
    return rows
