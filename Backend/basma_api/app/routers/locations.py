from __future__ import annotations

from fastapi import APIRouter, Depends

from ..db import get_db
from ..schemas import GovernmentOut, DistrictOut, AreaOut, AreaCreate
from ..controllers.locations_controller import (
    list_governments as controller_list_governments,
    list_districts as controller_list_districts,
    list_areas as controller_list_areas,
    create_area as controller_create_area,
)

router = APIRouter(prefix="/locations", tags=["locations"])


@router.get("/governments", response_model=list[GovernmentOut])
def list_governments(db=Depends(get_db)):
    return controller_list_governments(db=db)


@router.get("/governments/{government_id}/districts", response_model=list[DistrictOut])
def list_districts(government_id: int, db=Depends(get_db)):
    return controller_list_districts(government_id=government_id, db=db)


@router.get("/districts/{district_id}/areas", response_model=list[AreaOut])
def list_areas(district_id: int, db=Depends(get_db)):
    return controller_list_areas(district_id=district_id, db=db)


@router.post("/areas", response_model=AreaOut, status_code=201)
def create_area(payload: AreaCreate, db=Depends(get_db)):
    return controller_create_area(payload=payload, db=db)