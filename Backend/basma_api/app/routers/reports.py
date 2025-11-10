from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import select
from ..db import get_db
from ..models import Report, ReportStatus, ReportType, Location
from ..schemas import (
    ReportCreate, ReportOut, ReportTypeOut, ReportStatusOut,
    ReportFilter, AdoptRequest, CompleteRequest
)
from ..security import get_current_user_payload
from ..utils import generate_report_code  # keep your existing util

router = APIRouter(prefix="/reports", tags=["reports"])

@router.get("/types", response_model=list[ReportTypeOut])
def list_types(db: Session = Depends(get_db)):
    return db.scalars(select(ReportType)).all()

@router.get("/status", response_model=list[ReportStatusOut])
def list_statuses(db: Session = Depends(get_db)):
    return db.scalars(select(ReportStatus)).all()

@router.get("", response_model=list[ReportOut])
def list_reports(
    area_id: int | None = Query(default=None),
    status_code: str | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = select(Report).order_by(Report.id.desc())
    if area_id is not None:
        stmt = stmt.where(Report.area_id == area_id)
    if status_code:
        st = db.scalar(select(ReportStatus).where(ReportStatus.code == status_code))
        if not st:
            raise HTTPException(status_code=400, detail="Invalid status_code")
        stmt = stmt.where(Report.status_id == st.id)
    stmt = stmt.limit(limit).offset(offset)
    return db.scalars(stmt).all()

@router.get("/{report_id}", response_model=ReportOut)
def get_report(report_id: int, db: Session = Depends(get_db)):
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(status_code=404, detail="Report not found")
    return rp

@router.post("", response_model=ReportOut, status_code=201)
def create_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),  # keep auth if you already require it
):
    # 1) resolve status "under_review"
    under = db.scalar(select(ReportStatus).where(ReportStatus.code == "under_review"))
    if not under:
        raise HTTPException(status_code=500, detail="Missing 'under_review' status")

    # 2) ensure report_type exists
    rtype = db.get(ReportType, payload.report_type_id)
    if not rtype:
        raise HTTPException(status_code=400, detail="Invalid report_type_id")

    # 3) resolve location
    location_id: int
    if payload.location_id is not None:
        # use existing
        loc = db.get(Location, payload.location_id)
        if not loc or loc.area_id != payload.area_id:
            raise HTTPException(status_code=400, detail="Invalid location_id for area")
        location_id = loc.id
    else:
        # create new location
        nl = payload.new_location
        assert nl is not None  # validated by schema
        loc = Location(
            area_id=nl.area_id,
            name_ar=nl.name_ar,
            name_en=nl.name_en,
            latitude=nl.latitude,
            longitude=nl.longitude,
        )
        db.add(loc)
        db.flush()  # get loc.id
        location_id = loc.id

    # 4) create report
    rp = Report(
        report_code=generate_report_code(prefix="UF"),  # e.g. "UF-2026-11-6-2003"
        report_type_id=payload.report_type_id,
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        description_ar=payload.description_ar,
        description_en=payload.description_en,
        note=payload.note,
        image_before_url=payload.image_before_url,
        status_id=under.id,
        government_id=payload.government_id,
        district_id=payload.district_id,
        area_id=payload.area_id,
        location_id=location_id,
        user_id=int(current.get("sub")) if current and current.get("sub") else None,
        reported_by_name=payload.reported_by_name,
    )
    db.add(rp)
    db.commit()
    db.refresh(rp)
    return rp

@router.patch("/{report_id}/adopt", response_model=ReportOut)
def adopt_report(report_id: int, body: AdoptRequest, db: Session = Depends(get_db)):
    # unchanged…
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(status_code=404, detail="Report not found")
    rp.adopted_by_type = body.adopted_by_type
    rp.adopted_by_id = body.adopted_by_id

    inprog = db.scalar(select(ReportStatus).where(ReportStatus.code == "in_progress"))
    if not inprog:
        raise HTTPException(status_code=500, detail="Missing 'in_progress' status")
    rp.status_id = inprog.id
    db.commit(); db.refresh(rp)
    return rp

@router.patch("/{report_id}/complete", response_model=ReportOut)
def complete_report(report_id: int, body: CompleteRequest, db: Session = Depends(get_db)):
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(status_code=404, detail="Report not found")
    rp.image_after_url = body.image_after_url
    done = db.scalar(select(ReportStatus).where(ReportStatus.code == "completed"))
    if not done:
        raise HTTPException(status_code=500, detail="Missing 'completed' status")
    rp.status_id = done.id
    db.commit(); db.refresh(rp)
    return rp
