from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..db import get_db
from ..models import Report, ReportStatus, ReportType, Location, Citizen, Initiative
from ..schemas import (
    ReportCreate,
    ReportOut,
    ReportStatusOut,
    ReportTypeOut,
    AdoptRequest,
    CompleteRequest,
)
from ..security import get_current_user_payload
from ..utils import generate_report_code

router = APIRouter(prefix="/reports", tags=["reports"])


# ============================================================
# TYPES
# ============================================================


@router.get("/types", response_model=list[ReportTypeOut])
def list_types(db: Session = Depends(get_db)):
    return db.scalars(select(ReportType)).all()


@router.get("/status", response_model=list[ReportStatusOut])
def list_status(db: Session = Depends(get_db)):
    return db.scalars(select(ReportStatus)).all()


# ============================================================
# LIST REPORTS
# ============================================================


@router.get("", response_model=list[ReportOut])
def list_reports(
    area_id: int | None = Query(None),
    status_id: int | None = Query(None),
    status_code: str | None = Query(None),
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Report).order_by(Report.id.desc())

    if area_id:
        stmt = stmt.where(Report.area_id == area_id)

    # PRIORITY: status_code
    if status_code:
        st = db.scalar(select(ReportStatus).where(ReportStatus.code == status_code))
        if not st:
            return []
        stmt = stmt.where(Report.status_id == st.id)

    elif status_id:
        stmt = stmt.where(Report.status_id == status_id)

    stmt = stmt.limit(limit).offset(offset)
    return db.scalars(stmt).all()


# ============================================================
# GET REPORT
# ============================================================


@router.get("/{report_id}", response_model=ReportOut)
def get_report(report_id: int, db: Session = Depends(get_db)):
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(404, "Report not found")
    return rp


# ============================================================
# CREATE REPORT
# ============================================================


@router.post("", response_model=ReportOut, status_code=201)
def create_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
):

    st_under = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "under_review")
    )
    if not st_under:
        raise HTTPException(500, "Missing status under_review")

    if not db.get(ReportType, payload.report_type_id):
        raise HTTPException(400, "Invalid report_type_id")

    # location
    if payload.location_id:
        loc = db.get(Location, payload.location_id)
        if not loc:
            raise HTTPException(400, "Invalid location_id")
        location_id = loc.id

    else:
        nl = payload.new_location
        if not nl:
            raise HTTPException(400, "Missing location")

        loc = Location(
            area_id=nl.area_id,
            name_ar=nl.name_ar,
            longitude=nl.longitude,
            latitude=nl.latitude,
        )
        db.add(loc)
        db.flush()
        location_id = loc.id

    rp = Report(
        report_code=generate_report_code(prefix="UF"),
        report_type_id=payload.report_type_id,
        name_ar=payload.name_ar,
        description_ar=payload.description_ar,
        note=payload.note,
        image_before_url=payload.image_before_url,
        status_id=st_under.id,
        government_id=payload.government_id,
        district_id=payload.district_id,
        area_id=payload.area_id,
        location_id=location_id,
        user_id=int(current.get("sub")) if current else None,
        reported_by_name=payload.reported_by_name,
    )

    db.add(rp)
    db.commit()
    db.refresh(rp)
    return rp


# ============================================================
# OPEN REPORT (1 → 2)
# ============================================================


@router.patch("/{report_id}/open", response_model=ReportOut)
def open_report(report_id: int, db: Session = Depends(get_db)):

    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(404, "Report not found")

    st_under = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "under_review")
    )
    st_open = db.scalar(select(ReportStatus).where(ReportStatus.code == "open"))

    if rp.status_id != st_under.id:
        raise HTTPException(400, "Report must be under_review")

    rp.status_id = st_open.id
    db.commit()
    db.refresh(rp)
    return rp


# ============================================================
# ADOPT REPORT (2 → 3)
# ============================================================


@router.patch("/{report_id}/adopt", response_model=ReportOut)
def adopt_report(
    report_id: int,
    payload: AdoptRequest,
    db: Session = Depends(get_db),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(404, "Report not found")

    if report.status_id != 2:  # open
        raise HTTPException(400, "Cannot adopt a non-open report")

    if payload.adopted_by_type == 1:
        # citizen
        if not db.get(Citizen, payload.adopted_by_id):
            raise HTTPException(400, "Citizen not found")
    elif payload.adopted_by_type == 2:
        # initiative
        if not db.get(Initiative, payload.adopted_by_id):
            raise HTTPException(400, "Initiative not found")

    report.adopted_by_id = payload.adopted_by_id
    report.adopted_by_type = payload.adopted_by_type
    report.status_id = 3  # in_progress

    db.commit()
    db.refresh(report)
    return report


# ============================================================
# COMPLETE REPORT (3 → 4)
# ============================================================


@router.patch("/{report_id}/complete", response_model=ReportOut)
def complete_report(
    report_id: int, body: CompleteRequest, db: Session = Depends(get_db)
):

    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(404, "Report not found")

    st_prog = db.scalar(select(ReportStatus).where(ReportStatus.code == "in_progress"))
    st_done = db.scalar(select(ReportStatus).where(ReportStatus.code == "completed"))

    if rp.status_id != st_prog.id:
        raise HTTPException(400, "Report is not in progress")

    rp.image_after_url = body.image_after_url
    rp.note = body.note
    rp.status_id = st_done.id

    # Increment completed count
    if rp.adopted_by_type == 1:
        c = db.get(Citizen, rp.adopted_by_id)
        if c:
            c.reports_completed_count += 1
    elif rp.adopted_by_type == 2:
        i = db.get(Initiative, rp.adopted_by_id)
        if i:
            i.reports_completed_count += 1

    db.commit()
    db.refresh(rp)
    return rp
