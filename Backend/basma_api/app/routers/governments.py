from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import governments_controller as controller

router = APIRouter(prefix="/governments", tags=["governments"])


@router.get("", response_model=List[controller.GovernmentOut])
def list_governments(db: Session = Depends(get_db)):
    return controller.list_governments(db)


@router.get("/{government_id}", response_model=controller.GovernmentOut)
def get_government(government_id: int, db: Session = Depends(get_db)):
    return controller.get_government(government_id, db)


@router.post("", response_model=controller.GovernmentOut, status_code=201)
def create_government(payload: controller.GovernmentCreate, db: Session = Depends(get_db)):
    return controller.create_government(payload, db)


@router.patch("/{government_id}", response_model=controller.GovernmentOut)
def update_government(government_id: int, payload: controller.GovernmentUpdate, db: Session = Depends(get_db)):
    return controller.update_government(government_id, payload, db)


@router.delete("/{government_id}", status_code=204)
def delete_government(government_id: int, db: Session = Depends(get_db)):
    return controller.delete_government(government_id, db)


# Nested: /governments/{id}/districts
@router.get("/{government_id}/districts", response_model=List[controller.DistrictOut])
def list_districts_of_government(government_id: int, db: Session = Depends(get_db)):
    return controller.list_districts_of_government(government_id, db)
