# app/routers/admin_reports.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_admin_user
from ..models import Report
from ..schemas_admin import AdminReportOut, AdminReportUpdate

router = APIRouter(
    prefix="/admin/reports",
    tags=["Admin Reports"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[AdminReportOut])
def list_reports(
    db: Session = Depends(get_db),
    status_id: int | None = Query(None),
    q: str | None = Query(None, description="بحث بالوصف أو الكود"),
):
    query = db.query(Report)

    if status_id is not None:
        query = query.filter(Report.status_id == status_id)
    if q:
        query = query.filter(
            (Report.report_code.like(f"%{q}%")) |
            (Report.name_ar.like(f"%{q}%"))
        )

    reports = query.order_by(Report.id.desc()).all()
    return reports


@router.get("/{report_id}", response_model=AdminReportOut)
def get_report(
    report_id: int,
    db: Session = Depends(get_db),
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")
    return report


@router.put("/{report_id}", response_model=AdminReportOut)
def update_report(
    report_id: int,
    data: AdminReportUpdate,
    db: Session = Depends(get_db),
):
    report = db.query(Report).filter(Report.id == report_id).first()
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


@router.post("/{report_id}/approve", response_model=AdminReportOut)
def approve_report(
    report_id: int,
    db: Session = Depends(get_db),
):
    """
    زر الموافقة: يغيّر status_id من 1 إلى مثلاً 2 (تحتاج تعرف ID حالة الموافقة).
    هنا أفترض أن:
      1 = جديد / قيد المراجعة
      2 = معتمد
    عدّل IDs حسب جدولك.
    """
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")

    if report.status_id != 1:
        raise HTTPException(
            status_code=400,
            detail="لا يمكن اعتماد بلاغ ليست حالته (جديد)",
        )

    report.status_id = 2  # عدّلها حسب ID حالة 'معتمد' في جدول report_status
    db.commit()
    db.refresh(report)
    return report


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_report(
    report_id: int,
    db: Session = Depends(get_db),
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="البلاغ غير موجود")
    db.delete(report)
    db.commit()
    return
