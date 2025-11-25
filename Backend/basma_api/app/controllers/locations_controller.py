from __future__ import annotations

from fastapi import HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..db import get_db
from ..models import Government, District, Area


def list_governments(db: Session = Depends(get_db)):
    stmt = (
        select(Government)
        .where(Government.is_active == 1)
        .order_by(Government.name_ar.asc())
    )
    return db.scalars(stmt).all()


def list_districts(government_id: int, db: Session = Depends(get_db)):
    gov = db.get(Government, government_id)
    if not gov:
        raise HTTPException(status_code=404, detail="Government not found")

    stmt = (
        select(District)
        .where(
            District.government_id == government_id,
            District.is_active == 1,
        )
        .order_by(District.name_ar.asc())
    )
    return db.scalars(stmt).all()


def list_areas(district_id: int, db: Session = Depends(get_db)):
    dist = db.get(District, district_id)
    if not dist:
        raise HTTPException(status_code=404, detail="District not found")

    stmt = (
        select(Area)
        .where(
            Area.district_id == district_id,
            Area.is_active == 1,
        )
        .order_by(Area.name_ar.asc())
    )
    return db.scalars(stmt).all()


def create_area(payload, db: Session = Depends(get_db)):
    dist = db.get(District, payload.district_id)
    if not dist:
        raise HTTPException(status_code=400, detail="Invalid district_id")

    existing = db.scalar(
        select(Area).where(
            Area.district_id == payload.district_id,
            (
                (Area.name_ar == payload.name_ar)
                | (Area.name_en == payload.name_en)
            ),
        )
    )
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Area with this name already exists in this district",
        )

    area = Area(
        district_id=payload.district_id,
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        is_active=1,
    )
    db.add(area)
    db.commit()
    db.refresh(area)
    return area
