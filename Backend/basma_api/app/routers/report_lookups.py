# app/routers/report_lookups.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import report_lookups_controller as controller

router = APIRouter(
    prefix="",
    tags=["Lookups"],
)


@router.get("/report-status", response_model=list[controller.ReportStatusOut])
def list_report_statuses(db: Session = Depends(get_db)):
    return controller.list_report_statuses(db)


@router.get("/account-types", response_model=list[controller.AccountTypeOut])
def list_account_types(db: Session = Depends(get_db)):
    return controller.list_account_types(db)


@router.get("/report-types", response_model=list[controller.ReportTypeOut])
def list_report_types(db: Session = Depends(get_db)):
    return controller.list_report_types(db)


@router.get("/governments", response_model=list[controller.GovernmentOut])
def list_governments(db: Session = Depends(get_db)):
    return controller.list_governments(db)


@router.get("/account-options", response_model=list[controller.AccountOptionOut])
def list_account_options(db: Session = Depends(get_db)):
    return controller.list_account_options(db)
