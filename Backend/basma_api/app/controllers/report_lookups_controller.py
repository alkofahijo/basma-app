from __future__ import annotations

from fastapi import Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.schemas import (
    ReportStatusOut,
    AccountTypeOut,
    ReportTypeOut,
    AccountOptionOut,
    GovernmentOut,
)


def list_report_statuses(db: Session = Depends(get_db)) -> list[ReportStatusOut]:
    rows = db.query(models.ReportStatus).order_by(models.ReportStatus.id).all()
    return rows


def list_account_types(db: Session = Depends(get_db)) -> list[AccountTypeOut]:
    rows = db.query(models.AccountType).order_by(models.AccountType.id).all()
    return rows


def list_report_types(db: Session = Depends(get_db)) -> list[ReportTypeOut]:
    rows = db.query(models.ReportType).order_by(models.ReportType.id).all()
    return rows


def list_governments(db: Session = Depends(get_db)) -> list[GovernmentOut]:
    rows = db.query(models.Government).order_by(models.Government.id).all()
    return rows


def list_account_options(db: Session = Depends(get_db)) -> list[AccountOptionOut]:
    rows = (
        db.query(models.Account)
        .filter(models.Account.is_active == 1)
        .order_by(models.Account.name_ar)
        .all()
    )
    return rows
