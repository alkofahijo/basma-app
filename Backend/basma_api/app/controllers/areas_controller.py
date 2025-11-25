from __future__ import annotations

from typing import List

from fastapi import Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.schemas import AreaCreate, AreaOut, AreaUpdate, LocationOut


def list_areas(db: Session = Depends(get_db)) -> List[AreaOut]:
    rows = db.execute(select(models.Area).order_by(models.Area.id.asc())).scalars().all()
    return rows


def get_area(area_id: int, db: Session = Depends(get_db)) -> AreaOut:
    obj = db.get(models.Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj


def create_area(payload: AreaCreate, db: Session = Depends(get_db)) -> AreaOut:
    if not db.get(models.District, payload.district_id):
        raise HTTPException(400, "Invalid district_id")
    obj = models.Area(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def update_area(area_id: int, payload: AreaUpdate, db: Session = Depends(get_db)) -> AreaOut:
    obj = db.get(models.Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    data = payload.model_dump(exclude_unset=True)
    if "district_id" in data and data["district_id"] is not None:
        if not db.get(models.District, data["district_id"]):
            raise HTTPException(400, "Invalid district_id")
    for k, v in data.items():
        setattr(obj, k, v)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def delete_area(area_id: int, db: Session = Depends(get_db)) -> None:
    obj = db.get(models.Area, area_id)
    if not obj:
        raise HTTPException(404, "Not found")
    try:
        db.delete(obj)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Cannot delete: dependent locations exist")
    return None


def list_locations_of_area(area_id: int, db: Session = Depends(get_db)) -> List[LocationOut]:
    if not db.get(models.Area, area_id):
        raise HTTPException(404, "Area not found")
    rows = db.execute(
        select(models.Location).where(models.Location.area_id == area_id).order_by(models.Location.id.asc())
    ).scalars().all()
    return rows
