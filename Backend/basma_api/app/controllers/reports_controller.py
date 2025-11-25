from __future__ import annotations

from typing import Optional, List

from fastapi import HTTPException, status, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import select

from ..db import get_db
from ..models import (
    Report,
    ReportStatus,
    ReportType,
    Location,
    Government,
    District,
    Area,
    Account,
)
from ..schemas import (
    ReportCreate,
    ReportOut,
    ReportStatusOut,
    ReportTypeOut,
    ReportPublicOut,
)
from ..security import get_current_user_payload
from ..utils import generate_report_code


# Local request models kept here to avoid import cycles
class AdoptReportRequest(BaseModel):
    account_id: int


class CompleteReportRequest(BaseModel):
    image_after_url: str
    note: Optional[str] = None


def list_types(db: Session = Depends(get_db)) -> List[ReportType]:
    return db.scalars(select(ReportType)).all()


def list_status(db: Session = Depends(get_db)) -> List[ReportStatus]:
    return db.scalars(select(ReportStatus)).all()


def list_public_reports(
    status_id: int | None = None,
    government_id: int | None = None,
    district_id: int | None = None,
    area_id: int | None = None,
    report_type_id: int | None = None,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
) -> List[ReportPublicOut]:
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


def list_my_reports(
    status_id: int | None = None,
    government_id: int | None = None,
    district_id: int | None = None,
    area_id: int | None = None,
    report_type_id: int | None = None,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
) -> List[ReportPublicOut]:
    if not current:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated"
        )

    account_id = current.get("account_id")
    user_type = current.get("user_type")

    if user_type != 2 or account_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only normal account users can list their adopted reports",
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
            Report.adopted_by_account_id == int(account_id),
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


def list_reports(
    area_id: int | None = None,
    status_id: int | None = None,
    status_code: str | None = None,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
) -> List[ReportOut]:
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


def get_report(report_id: int, db: Session = Depends(get_db)) -> ReportOut:
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
            Report.adopted_by_account_id,
            Account.name_ar.label("adopted_by_account_name"),
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
        .join(Account, Report.adopted_by_account_id == Account.id, isouter=True)
        .where(Report.id == report_id)
    )

    row = db.execute(stmt).mappings().first()
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    return ReportOut(**row)


def create_report(
    payload: ReportCreate,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
) -> Report:
    st_under = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "under_review")
    )
    if not st_under:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Missing status 'under_review'",
        )

    if not db.get(ReportType, payload.report_type_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid report_type_id"
        )

    # 1) Location
    location_id: int

    if payload.location_id is not None:
        loc = db.get(Location, payload.location_id)
        if not loc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid location_id"
            )
        location_id = loc.id
    else:
        nl = payload.new_location
        if not nl:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing location information",
            )

        loc = Location(
            area_id=nl.area_id,
            name_ar=nl.name_ar,
            longitude=nl.longitude,
            latitude=nl.latitude,
        )
        db.add(loc)
        db.flush()
        location_id = loc.id

    # 2) user_id from JWT
    user_id: Optional[int] = None
    if current:
        sub = current.get("sub")
        try:
            user_id = int(sub) if sub is not None else None
        except (TypeError, ValueError):
            user_id = None

    # 3) create report
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
        user_id=user_id,
        reported_by_name=payload.reported_by_name,
    )

    db.add(rp)
    db.commit()
    db.refresh(rp)
    return rp


def open_report(report_id: int, db: Session = Depends(get_db)) -> Report:
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    st_under = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "under_review")
    )
    st_open = db.scalar(select(ReportStatus).where(ReportStatus.code == "open"))

    if not st_under or not st_open:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Missing status configuration",
        )

    if rp.status_id != st_under.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Report must be under_review",
        )

    rp.status_id = st_open.id
    db.commit()
    db.refresh(rp)
    return rp


def adopt_report(
    report_id: int,
    payload: AdoptReportRequest,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
) -> Report:
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    st_open = db.scalar(select(ReportStatus).where(ReportStatus.code == "open"))
    st_in_progress = db.scalar(
        select(ReportStatus).where(ReportStatus.code == "in_progress")
    )

    if not st_open or not st_in_progress:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Missing status configuration",
        )

    if report.status_id != st_open.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot adopt a non-open report",
        )

    account = db.get(Account, payload.account_id)
    if not account or account.is_active != 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Account not found or inactive",
        )

    user_type = current.get("user_type")
    current_account_id = current.get("account_id")

    if user_type == 1:
        pass
    elif user_type == 2:
        if current_account_id is None or int(current_account_id) != account.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only adopt reports for your own account",
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User type not allowed to adopt reports",
        )

    report.adopted_by_account_id = account.id
    report.status_id = st_in_progress.id

    db.commit()
    db.refresh(report)
    return report


def complete_report(
    report_id: int,
    body: CompleteReportRequest,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
) -> Report:
    rp = db.get(Report, report_id)
    if not rp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    st_prog = db.scalar(select(ReportStatus).where(ReportStatus.code == "in_progress"))
    st_done = db.scalar(select(ReportStatus).where(ReportStatus.code == "completed"))

    if not st_prog or not st_done:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Missing status configuration",
        )

    if rp.status_id != st_prog.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Report is not in progress"
        )

    user_type = current.get("user_type")
    current_account_id = current.get("account_id")

    if user_type == 1:
        pass
    elif user_type == 2:
        if not rp.adopted_by_account_id or current_account_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not allowed to complete this report",
            )
        if int(current_account_id) != int(rp.adopted_by_account_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not allowed to complete this report",
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User type not allowed to complete reports",
        )

    rp.image_after_url = body.image_after_url
    rp.note = body.note
    rp.status_id = st_done.id

    if rp.adopted_by_account_id:
        acc = db.get(Account, rp.adopted_by_account_id)
        if acc:
            acc.reports_completed_count += 1
            db.add(acc)

    db.commit()
    db.refresh(rp)
    return rp
