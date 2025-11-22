# app/routers/report_lookups.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..deps import get_db
from ..models import ReportStatus, AccountType, Government
from ..schemas import ReportStatusOut, AccountTypeOut
from ..schemas_admin import GovernmentOut

router = APIRouter(
    prefix="",  # المسارات ستكون مباشرة مثل /report-status و /account-types و /governments
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


@router.get("/governments", response_model=list[GovernmentOut])
def list_governments(db: Session = Depends(get_db)):
    """
    إرجاع جميع المحافظات لاستخدامها في صفحات الحسابات والبلاغات كـ dropdown.
    """
    rows = db.query(Government).order_by(Government.id).all()
    return rows
