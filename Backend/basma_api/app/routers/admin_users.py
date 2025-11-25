# app/routers/admin_users.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import admin_users_controller as controller
from app.deps import get_current_admin_user

router = APIRouter(
    prefix="/admin/users",
    tags=["Admin Users"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[controller.AdminUserOut])
def list_users(db: Session = Depends(get_db), q: str | None = None):
    return controller.list_users(db=db, q=q)


@router.post("/", response_model=controller.AdminUserOut, status_code=201)
def create_user(data: controller.AdminUserCreate, db: Session = Depends(get_db)):
    return controller.create_user(data, db)


@router.get("/{user_id}", response_model=controller.AdminUserOut)
def get_user(user_id: int, db: Session = Depends(get_db)):
    return controller.get_user(user_id, db)


@router.put("/{user_id}", response_model=controller.AdminUserOut)
def update_user(user_id: int, data: controller.AdminUserUpdate, db: Session = Depends(get_db)):
    return controller.update_user(user_id, data, db)


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
    return controller.delete_user(user_id, db)
