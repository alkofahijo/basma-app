# app/routers/admin_auth.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import admin_auth_controller as controller

router = APIRouter(
    prefix="/admin",
    tags=["Admin Auth"],
)


@router.post("/login", response_model=controller.TokenOut)
def admin_login(data: controller.AdminLoginRequest, db: Session = Depends(get_db)):
    return controller.admin_login(data, db)
