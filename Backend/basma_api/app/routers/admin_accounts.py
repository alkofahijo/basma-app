# app/routers/admin_accounts.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import admin_accounts_controller as controller
from app.deps import get_current_admin_user

router = APIRouter(
    prefix="/admin/accounts",
    tags=["Admin Accounts"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[controller.AdminAccountOut])
def list_accounts(
    db: Session = Depends(get_db),
    account_type_id: int | None = None,
    q: str | None = None,
):
    return controller.list_accounts(db=db, account_type_id=account_type_id, q=q)


@router.post("/", response_model=controller.AdminAccountOut, status_code=201)
def create_account(data: controller.AdminAccountCreate, db: Session = Depends(get_db)):
    return controller.create_account(data, db)


@router.get("/{account_id}", response_model=controller.AdminAccountOut)
def get_account(account_id: int, db: Session = Depends(get_db)):
    return controller.get_account(account_id, db)


@router.put("/{account_id}", response_model=controller.AdminAccountOut)
def update_account(account_id: int, data: controller.AdminAccountUpdate, db: Session = Depends(get_db)):
    return controller.update_account(account_id, data, db)


@router.delete("/{account_id}", status_code=204)
def delete_account(account_id: int, db: Session = Depends(get_db)):
    return controller.delete_account(account_id, db)
