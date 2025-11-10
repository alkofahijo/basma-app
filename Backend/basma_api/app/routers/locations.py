from __future__ import annotations
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import Government, District, Area, Location
from ..schemas import GovernmentOut, DistrictOut, AreaOut, LocationOut
from typing import List

router = APIRouter(prefix="/locations", tags=["locations"])

@router.get("/governments", response_model=List[GovernmentOut])
def governments(db: Session = Depends(get_db)):
    return db.execute(select(Government)).scalars().all()

@router.get("/governments/{gov_id}/districts", response_model=List[DistrictOut])
def districts(gov_id: int, db: Session = Depends(get_db)):
    return db.execute(select(District).where(District.government_id==gov_id)).scalars().all()

@router.get("/districts/{d_id}/areas", response_model=List[AreaOut])
def areas(d_id: int, db: Session = Depends(get_db)):
    return db.execute(select(Area).where(Area.district_id==d_id)).scalars().all()

@router.get("/areas/{a_id}/locations", response_model=List[LocationOut])
def locations(a_id: int, db: Session = Depends(get_db)):
    return db.execute(select(Location).where(Location.area_id==a_id)).scalars().all()
