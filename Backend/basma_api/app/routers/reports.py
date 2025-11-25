from __future__ import annotations

from typing import Optional, List

from fastapi import APIRouter, Depends, Query, status

from ..db import get_db
from ..schemas import (
    ReportTypeOut,
    ReportStatusOut,
    ReportPublicOut,
    ReportOut,
    ReportCreate,
)
from ..security import get_current_user_payload

from ..controllers.reports_controller import (
    list_types as controller_list_types,
    list_status as controller_list_status,
    list_public_reports as controller_list_public_reports,
    list_my_reports as controller_list_my_reports,
    list_reports as controller_list_reports,
    get_report as controller_get_report,
    create_report as controller_create_report,
    open_report as controller_open_report,
    adopt_report as controller_adopt_report,
    complete_report as controller_complete_report,
)
from ..controllers.reports_controller import AdoptReportRequest, CompleteReportRequest

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/types", response_model=List[ReportTypeOut])
def list_types(db=Depends(get_db)):
    return controller_list_types(db=db)


@router.get("/status", response_model=List[ReportStatusOut])
def list_status(db=Depends(get_db)):
    return controller_list_status(db=db)


@router.get("/public", response_model=List[ReportPublicOut])
def list_public_reports(
    status_id: int | None = Query(None),
    government_id: int | None = Query(None),
    district_id: int | None = Query(None),
    area_id: int | None = Query(None),
    report_type_id: int | None = Query(None),
    limit: int = Query(20, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return controller_list_public_reports(
        status_id=status_id,
        government_id=government_id,
        district_id=district_id,
        area_id=area_id,
        report_type_id=report_type_id,
        limit=limit,
        offset=offset,
        db=db,
    )


@router.get("/my", response_model=List[ReportPublicOut])
def list_my_reports(
    status_id: int | None = Query(None),
    government_id: int | None = Query(None),
    district_id: int | None = Query(None),
    area_id: int | None = Query(None),
    report_type_id: int | None = Query(None),
    limit: int = Query(20, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
    current=Depends(get_current_user_payload),
):
    return controller_list_my_reports(
        status_id=status_id,
        government_id=government_id,
        district_id=district_id,
        area_id=area_id,
        report_type_id=report_type_id,
        limit=limit,
        offset=offset,
        db=db,
        current=current,
    )


@router.get("", response_model=List[ReportOut])
def list_reports(
    area_id: int | None = Query(None),
    status_id: int | None = Query(None),
    status_code: str | None = Query(None),
    limit: int = Query(20, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db=Depends(get_db),
):
    return controller_list_reports(
        area_id=area_id, status_id=status_id, status_code=status_code, limit=limit, offset=offset, db=db
    )


@router.get("/{report_id}", response_model=ReportOut)
def get_report(report_id: int, db=Depends(get_db)):
    return controller_get_report(report_id=report_id, db=db)


@router.post("", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
def create_report(payload: ReportCreate, db=Depends(get_db), current=Depends(get_current_user_payload)):
    return controller_create_report(payload=payload, db=db, current=current)


@router.patch("/{report_id}/open", response_model=ReportOut)
def open_report(report_id: int, db=Depends(get_db)):
    return controller_open_report(report_id=report_id, db=db)


@router.patch("/{report_id}/adopt", response_model=ReportOut)
def adopt_report(report_id: int, payload: AdoptReportRequest, db=Depends(get_db), current=Depends(get_current_user_payload)):
    return controller_adopt_report(report_id=report_id, payload=payload, db=db, current=current)


@router.patch("/{report_id}/complete", response_model=ReportOut)
def complete_report(report_id: int, body: CompleteReportRequest, db=Depends(get_db), current=Depends(get_current_user_payload)):
    return controller_complete_report(report_id=report_id, body=body, db=db, current=current)
