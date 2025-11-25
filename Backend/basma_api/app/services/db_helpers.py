from __future__ import annotations

from typing import Optional, Tuple
from sqlalchemy.orm import Session

from app import models


def get_or_create_government(db: Session, name_ar: str, name_en: Optional[str] = None) -> models.Government:
    obj = db.query(models.Government).filter(models.Government.name_ar == name_ar).first()
    if obj:
        return obj
    # `Government` model currently only stores `name_ar`; avoid passing `name_en` which is not a column.
    obj = models.Government(name_ar=name_ar, is_active=1)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_or_create_district(db: Session, government_id: int, name_ar: str, name_en: Optional[str] = None) -> models.District:
    obj = (
        db.query(models.District)
        .filter(models.District.government_id == government_id, models.District.name_ar == name_ar)
        .first()
    )
    if obj:
        return obj
    # `District` model only defines `name_ar` (no `name_en` column). Do not pass `name_en`.
    obj = models.District(government_id=government_id, name_ar=name_ar, is_active=1)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


def get_or_create_area(db: Session, government_id: int, district_id: int, name_ar: str, name_en: Optional[str] = None) -> models.Area:
    obj = (
        db.query(models.Area)
        .filter(models.Area.district_id == district_id, models.Area.name_ar == name_ar)
        .first()
    )
    if obj:
        return obj
    # Note: `Area` model does not have a `government_id` column; only `district_id` is stored.
    obj = models.Area(district_id=district_id, name_ar=name_ar, name_en=name_en or name_ar, is_active=1)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj
