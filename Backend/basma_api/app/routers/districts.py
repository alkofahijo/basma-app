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
    from __future__ import annotations

    from typing import List

    from fastapi import APIRouter, Depends
    from sqlalchemy.orm import Session

    from app.db import get_db
    from app.controllers import districts_controller as controller

    router = APIRouter(prefix="/districts", tags=["districts"])


    @router.get("", response_model=List[controller.DistrictOut])
    def list_districts(db: Session = Depends(get_db)):
        return controller.list_districts(db)


    @router.get("/{district_id}", response_model=controller.DistrictOut)
    def get_district(district_id: int, db: Session = Depends(get_db)):
        return controller.get_district(district_id, db)


    @router.post("", response_model=controller.DistrictOut, status_code=201)
    def create_district(payload: controller.DistrictCreate, db: Session = Depends(get_db)):
        return controller.create_district(payload, db)


    @router.patch("/{district_id}", response_model=controller.DistrictOut)
    def update_district(district_id: int, payload: controller.DistrictUpdate, db: Session = Depends(get_db)):
        return controller.update_district(district_id, payload, db)


    @router.delete("/{district_id}", status_code=204)
    def delete_district(district_id: int, db: Session = Depends(get_db)):
        return controller.delete_district(district_id, db)


    # Nested: /districts/{id}/areas
    @router.get("/{district_id}/areas", response_model=List[controller.AreaOut])
    def list_areas_of_district(district_id: int, db: Session = Depends(get_db)):
        return controller.list_areas_of_district(district_id, db)
        raise HTTPException(409, "Cannot delete: dependent areas exist")
