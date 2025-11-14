from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..db import get_db
from ..models import (
    Report,
    ReportStatus,
    ReportType,
    Location,
    Citizen,
    Initiative,
    Government,
    District,
    Area,
)
from ..schemas import (
    ReportCreate,
    ReportOut,
    ReportStatusOut,
    ReportTypeOut,
    AdoptRequest,
    CompleteRequest,
    ReportPublicOut,
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
# PUBLIC LIST REPORTS (for guest UI with filters)
# ============================================================


@router.get("/public", response_model=list[ReportPublicOut])
def list_public_reports(
    status_id: int | None = Query(None),
    government_id: int | None = Query(None),
    district_id: int | None = Query(None),
    area_id: int | None = Query(None),
    report_type_id: int | None = Query(None),
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    stmt = (
        select(
            Report.id,
            Report.report_code,
            Report.report_type_id,
            Report.name_ar,
            Report.description_ar,
            Report.image_before_url,
            Report.status_id,
            Report.reported_at,
            Report.government_id,
            Government.name_ar.label("government_name_ar"),
            Report.district_id,
            District.name_ar.label("district_name_ar"),
            Report.area_id,
            Area.name_ar.label("area_name_ar"),
            ReportType.code.label("report_type_code"),
            ReportType.name_ar.label("report_type_name_ar"),
            ReportStatus.name_ar.label("status_name_ar"),
        )
        .join(ReportType, Report.report_type_id == ReportType.id)
        .join(ReportStatus, Report.status_id == ReportStatus.id)
        .join(Government, Report.government_id == Government.id, isouter=True)
        .join(District, Report.district_id == District.id, isouter=True)
        .join(Area, Report.area_id == Area.id, isouter=True)
        .where(Report.is_active == 1)
    )

    if status_id is not None:
        stmt = stmt.where(Report.status_id == status_id)

    if government_id is not None:
        stmt = stmt.where(Report.government_id == government_id)

    if district_id is not None:
        stmt = stmt.where(Report.district_id == district_id)

    if area_id is not None:
        stmt = stmt.where(Report.area_id == area_id)

    if report_type_id is not None:
        stmt = stmt.where(Report.report_type_id == report_type_id)

    stmt = stmt.order_by(Report.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).mappings().all()
    return [ReportPublicOut(**row) for row in rows]


# ============================================================
# MY REPORTS (for logged-in user: citizen / initiative)
# ============================================================


@router.get("/my", response_model=list[ReportPublicOut])
def list_my_reports(
    status_id: int | None = Query(None),
    government_id: int | None = Query(None),
    district_id: int | None = Query(None),
    area_id: int | None = Query(None),
    report_type_id: int | None = Query(None),
    limit: int = Query(100, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
):
    if not current:
        raise HTTPException(status_code=401, detail="Not authenticated")

    user_type = current.get("type")
    adopted_by_type: int | None = None
    adopted_by_id: int | None = None

    if user_type == "citizen":
        cid = current.get("citizen_id")
        if cid is None:
            raise HTTPException(status_code=400, detail="Missing citizen_id in token")
        adopted_by_type = 1
        adopted_by_id = int(cid)
    elif user_type == "initiative":
        iid = current.get("initiative_id")
        if iid is None:
            raise HTTPException(
                status_code=400, detail="Missing initiative_id in token"
            )
        adopted_by_type = 2
        adopted_by_id = int(iid)
    else:
        raise HTTPException(
            status_code=400, detail="User type not allowed to list own reports"
        )

    stmt = (
        select(
            Report.id,
            Report.report_code,
            Report.report_type_id,
            Report.name_ar,
            Report.description_ar,
            Report.image_before_url,
            Report.status_id,
            Report.reported_at,
            Report.government_id,
            Government.name_ar.label("government_name_ar"),
            Report.district_id,
            District.name_ar.label("district_name_ar"),
            Report.area_id,
            Area.name_ar.label("area_name_ar"),
            ReportType.code.label("report_type_code"),
            ReportType.name_ar.label("report_type_name_ar"),
            ReportStatus.name_ar.label("status_name_ar"),
        )
        .join(ReportType, Report.report_type_id == ReportType.id)
        .join(ReportStatus, Report.status_id == ReportStatus.id)
        .join(Government, Report.government_id == Government.id, isouter=True)
        .join(District, Report.district_id == District.id, isouter=True)
        .join(Area, Report.area_id == Area.id, isouter=True)
        .where(
            Report.is_active == 1,
            Report.adopted_by_type == adopted_by_type,
            Report.adopted_by_id == adopted_by_id,
        )
    )

    if status_id is not None:
        stmt = stmt.where(Report.status_id == status_id)

    if government_id is not None:
        stmt = stmt.where(Report.government_id == government_id)

    if district_id is not None:
        stmt = stmt.where(Report.district_id == district_id)

    if area_id is not None:
        stmt = stmt.where(Report.area_id == area_id)

    if report_type_id is not None:
        stmt = stmt.where(Report.report_type_id == report_type_id)

    stmt = stmt.order_by(Report.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).mappings().all()
    return [ReportPublicOut(**row) for row in rows]


# ============================================================
# LIST REPORTS (internal)
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
# GET REPORT (with joined Arabic names + location coords)
# ============================================================


@router.get("/{report_id}", response_model=ReportOut)
def get_report(report_id: int, db: Session = Depends(get_db)):
    stmt = (
        select(
            Report.id,
            Report.report_code,
            Report.report_type_id,
            Report.name_ar,
            Report.description_ar,
            Report.note,
            Report.image_before_url,
            Report.image_after_url,
            Report.status_id,
            Report.reported_at,
            Report.adopted_by_type,
            Report.adopted_by_id,
            Report.government_id,
            Government.name_ar.label("government_name_ar"),
            Report.district_id,
            District.name_ar.label("district_name_ar"),
            Report.area_id,
            Area.name_ar.label("area_name_ar"),
            Report.location_id,
            Location.name_ar.label("location_name_ar"),
            Location.longitude.label("location_longitude"),
            Location.latitude.label("location_latitude"),
            Report.user_id,
            Report.reported_by_name,
            Report.is_active,
            Report.created_at,
            Report.updated_at,
            ReportType.name_ar.label("report_type_name_ar"),
            ReportStatus.name_ar.label("status_name_ar"),
        )
        .join(ReportType, Report.report_type_id == ReportType.id)
        .join(ReportStatus, Report.status_id == ReportStatus.id)
        .join(Government, Report.government_id == Government.id, isouter=True)
        .join(District, Report.district_id == District.id, isouter=True)
        .join(Area, Report.area_id == Area.id, isouter=True)
        .join(Location, Report.location_id == Location.id, isouter=True)
        .where(Report.id == report_id)
    )

    row = db.execute(stmt).mappings().first()
    if not row:
        raise HTTPException(404, "Report not found")

    return ReportOut(**row)


# ============================================================
# CREATE REPORT
# ============================================================


@router.post("", response_model=ReportOut, status_code=201)
def create_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
):
    # حالة under_review
    st_under = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "under_review")
    )
    if not st_under:
        raise HTTPException(500, "Missing status under_review")

    # تحقق من نوع البلاغ
    if not db.get(ReportType, payload.report_type_id):
        raise HTTPException(400, "Invalid report_type_id")

    # -------- 1) الموقع (Location) --------
    location_id: int

    # إذا أرسل location_id جاهز
    if payload.location_id is not None:
        loc = db.get(Location, payload.location_id)
        if not loc:
            raise HTTPException(400, "Invalid location_id")
        location_id = loc.id

    # إذا أرسل new_location → ننشئ صف جديد في locations دائماً
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
        db.flush()  # للحصول على loc.id من قاعدة البيانات
        location_id = loc.id

    # -------- 2) إنشاء البلاغ --------
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

    # هنا نعتمد أن 2 = open, 3 = in_progress في جدول report_status
    if report.status_id != 2:  # open
        raise HTTPException(400, "Cannot adopt a non-open report")

    if payload.adopted_by_type == 1:
        if not db.get(Citizen, payload.adopted_by_id):
            raise HTTPException(400, "Citizen not found")
    elif payload.adopted_by_type == 2:
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
