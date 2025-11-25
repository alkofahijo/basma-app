from __future__ import annotations

from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app import models
from app.schemas_admin import AdminReportOut, AdminReportUpdate


def list_reports(
    db: Session = Depends(get_db),
    status_id: int | None = None,
    q: str | None = None,
) -> list[AdminReportOut]:
    query = db.query(models.Report)

    if status_id is not None:
        query = query.filter(models.Report.status_id == status_id)
    if q:
        query = query.filter(
            (models.Report.report_code.like(f"%{q}%")) |
            (models.Report.name_ar.like(f"%{q}%"))
        )

    reports = query.order_by(models.Report.id.desc()).all()
    return reports


def get_report(report_id: int, db: Session = Depends(get_db)) -> AdminReportOut:
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")
    return report


def update_report(report_id: int, data: AdminReportUpdate, db: Session = Depends(get_db)) -> AdminReportOut:
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")

    for field in [
        "report_type_id",
        "name_ar",
        "description_ar",
        "note",
        "image_before_url",
        "image_after_url",
        "status_id",
        "adopted_by_account_id",
        "government_id",
        "district_id",
        "area_id",
        "location_id",
        "is_active",
    ]:
        value = getattr(data, field)
        if value is not None:
            setattr(report, field, value)

    db.commit()
    db.refresh(report)
    return report


def approve_report(report_id: int, db: Session = Depends(get_db)) -> AdminReportOut:
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")

    if report.status_id != 1:
        raise HTTPException(
            status_code=400,
            detail="لا يمكن اعتماد بلاغ ليست حالته (جديد)",
        )

    report.status_id = 2
    db.commit()
    db.refresh(report)
    return report


def delete_report(report_id: int, db: Session = Depends(get_db)) -> None:
    report = db.query(models.Report).filter(models.Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")
    db.delete(report)
    db.commit()
    return None
