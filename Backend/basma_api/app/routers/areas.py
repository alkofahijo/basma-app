from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import areas_controller as controller

router = APIRouter(prefix="/areas", tags=["areas"])


@router.get("", response_model=List[controller.AreaOut])
def list_areas(db: Session = Depends(get_db)):
    return controller.list_areas(db)


@router.get("/{area_id}", response_model=controller.AreaOut)
def get_area(area_id: int, db: Session = Depends(get_db)):
    return controller.get_area(area_id, db)


@router.post("", response_model=controller.AreaOut, status_code=201)
def create_area(payload: controller.AreaCreate, db: Session = Depends(get_db)):
    return controller.create_area(payload, db)


@router.patch("/{area_id}", response_model=controller.AreaOut)
def update_area(area_id: int, payload: controller.AreaUpdate, db: Session = Depends(get_db)):
    return controller.update_area(area_id, payload, db)


@router.delete("/{area_id}", status_code=204)
def delete_area(area_id: int, db: Session = Depends(get_db)):
    return controller.delete_area(area_id, db)


# Nested: /areas/{id}/locations
@router.get("/{area_id}/locations", response_model=List[controller.LocationOut])
def list_locations_of_area(area_id: int, db: Session = Depends(get_db)):
    return controller.list_locations_of_area(area_id, db)
