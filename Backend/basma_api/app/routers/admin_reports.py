# app/routers/admin_reports.py
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import admin_reports_controller as controller
from app.deps import get_current_admin_user

router = APIRouter(
    prefix="/admin/reports",
    tags=["Admin Reports"],
    dependencies=[Depends(get_current_admin_user)],
)


@router.get("/", response_model=list[controller.AdminReportOut])
def list_reports(db: Session = Depends(get_db), status_id: int | None = None, q: str | None = None):
    return controller.list_reports(db=db, status_id=status_id, q=q)


@router.get("/{report_id}", response_model=controller.AdminReportOut)
def get_report(report_id: int, db: Session = Depends(get_db)):
    return controller.get_report(report_id, db)


@router.put("/{report_id}", response_model=controller.AdminReportOut)
def update_report(report_id: int, data: controller.AdminReportUpdate, db: Session = Depends(get_db)):
    return controller.update_report(report_id, data, db)


@router.post("/{report_id}/approve", response_model=controller.AdminReportOut)
def approve_report(report_id: int, db: Session = Depends(get_db)):
    return controller.approve_report(report_id, db)


@router.delete("/{report_id}", status_code=204)
def delete_report(report_id: int, db: Session = Depends(get_db)):
    return controller.delete_report(report_id, db)
