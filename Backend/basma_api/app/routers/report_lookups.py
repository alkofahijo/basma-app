# app/routers/report_lookups.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..models import Government
from ..schemas import GovernmentOut

from ..deps import get_db
from ..models import ReportStatus, AccountType, ReportType, Account
from ..schemas import (
    ReportStatusOut,
    AccountTypeOut,
    ReportTypeOut,
    AccountOptionOut,
)

router = APIRouter(
    prefix="",   # المسارات: /report-status, /account-types, /report-types, /account-options
    tags=["Lookups"],
)


@router.get("/report-status", response_model=list[ReportStatusOut])
def list_report_statuses(db: Session = Depends(get_db)):
    """
    إرجاع جميع حالات البلاغات لاستخدامها في الفلاتر والـ dropdown.
    """
    rows = db.query(ReportStatus).order_by(ReportStatus.id).all()
    return rows


@router.get("/account-types", response_model=list[AccountTypeOut])
def list_account_types(db: Session = Depends(get_db)):
    """
    إرجاع جميع أنواع الحسابات (مبادرة، بلدية، شركة ...) لاستخدامها في صفحة الحسابات.
    """
    rows = db.query(AccountType).order_by(AccountType.id).all()
    return rows


@router.get("/report-types", response_model=list[ReportTypeOut])
def list_report_types(db: Session = Depends(get_db)):
    """
    إرجاع أنواع البلاغات (تشوه بصري، حفر، نفايات...) لاستخدامها في شاشة تعديل البلاغات.
    """
    rows = db.query(ReportType).order_by(ReportType.id).all()
    return rows

@router.get("/governments", response_model=list[GovernmentOut])
def list_governments(db: Session = Depends(get_db)):
    rows = db.query(Government).order_by(Government.id).all()
    return rows

@router.get("/account-options", response_model=list[AccountOptionOut])
def list_account_options(db: Session = Depends(get_db)):
    """
    إرجاع قائمة مبسطة للحسابات (id + name_ar) لاستخدامها كـ dropdown
    لاختيار الحساب المتبني للبلاغ.
    """
    rows = (
      db.query(Account)
      .filter(Account.is_active == 1)
      .order_by(Account.name_ar)
      .all()
    )
    return rows
