from __future__ import annotations

from typing import Optional, Tuple, Dict, Any, TYPE_CHECKING

import httpx
from fastapi import HTTPException, status, UploadFile, File, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.db import get_db  # returns a database Session
from app import models      # SQLAlchemy models
from app.services.db_helpers import (
    get_or_create_government,
    get_or_create_district,
    get_or_create_area,
)

if TYPE_CHECKING:
    # Imported only for type-checkers (avoids heavy runtime import)
    from app.ml.report_classifier import ReportClassifierService
# Singleton instance (type declared as Any to avoid importing heavy ML modules at import-time)
classifier_service: Optional[object] = None

# عتبة الثقة على مستوى الـ API:
CONFIDENCE_THRESHOLD = 0.25

# مسار ملف نموذج التشوّه البصري (YOLOv5 .pt)
MODEL_PATH = "app/models/vp.pt"

# قيم خاصة بفئة "OTHERS" في قاعدة البيانات
OTHERS_REPORT_TYPE_ID = 11
OTHERS_CODE = "OTHERS"
OTHERS_NAME_AR = "أخرى"


def get_classifier_service():
    """Lazily import and return the ReportClassifierService instance.

    Import is deferred to runtime to avoid requiring heavy ML deps during app import/startup.
    """
    global classifier_service
    if classifier_service is None:
        # local import to avoid heavy dependency at module import time
        from app.ml.report_classifier import ReportClassifierService

        classifier_service = ReportClassifierService(
            model_path=MODEL_PATH,
            model_conf_threshold=0.1,
        )
    return classifier_service


class ResolveLocationRequest(BaseModel):
    latitude: float
    longitude: float


class LocationInfo(BaseModel):
    id: int
    name_ar: str
    name_en: Optional[str] = None


class LocationPoint(BaseModel):
    id: int
    name_ar: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class ResolveLocationResponse(BaseModel):
    government: LocationInfo
    district: LocationInfo
    area: LocationInfo
    location: Optional[LocationPoint] = None


class AnalyzeImageResponse(BaseModel):
    report_type_id: int
    report_type_name_ar: str
    confidence: float
    class_id: Optional[int] = None
    class_name: Optional[str] = Field(None, alias="class")
    suggested_title: str
    suggested_description: str


async def reverse_geocode(lat: float, lon: float) -> Dict[str, Any]:
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "format": "json",
        "lat": lat,
        "lon": lon,
        "zoom": 16,
        "addressdetails": 1,
        "accept-language": "ar,en",
    }
    headers = {
        "User-Agent": "basma-app/1.0",
        "Accept-Language": "ar,en",
    }
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()
    except httpx.HTTPError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="خدمة تحديد الموقع الجغرافي غير متاحة حالياً.",
        ) from e


def _clean_admin_name(value: str) -> str:
    if not value:
        return ""
    value = value.strip()
    for token in ["Governorate", "District", "Municipality"]:
        value = value.replace(token, "")
    return value.strip()


def _clean_area_name(value: str) -> str:
    if not value:
        return ""
    value = value.strip()
    for token in ["ناحية", "لواء", "قضاء", "بلدية", "مدينة"]:
        value = value.replace(token, "")
    return " ".join(value.split())


def extract_components(geo: Dict[str, Any]) -> Tuple[str, str, str, str]:
    address = geo.get("address", {}) or {}
    gov_name = address.get("state") or ""
    dist_name = address.get("state_district") or address.get("county") or ""
    area_name = (
        address.get("village")
        or address.get("neighbourhood")
        or address.get("suburb")
        or address.get("city")
        or address.get("county")
        or ""
    )
    loc_name = geo.get("display_name") or ""
    return gov_name, dist_name, area_name, loc_name


async def ai_resolve_location(payload: ResolveLocationRequest, db: Session = Depends(get_db)) -> ResolveLocationResponse:
    lat = payload.latitude
    lon = payload.longitude

    geo = await reverse_geocode(lat, lon)
    gov_raw, dist_raw, area_raw, loc_raw = extract_components(geo)

    gov_name = _clean_admin_name(gov_raw)
    dist_name = _clean_admin_name(dist_raw)
    area_name = _clean_area_name(area_raw)
    loc_name = loc_raw.strip() if loc_raw else ""

    if not gov_name or not dist_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="غير قادر على تحديد المحافظة أو اللواء من الإحداثيات.",
        )
    if not area_name:
        area_name = "منطقة بدون اسم"

    try:
        gov = get_or_create_government(db, gov_name)
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات المحافظة.",
        ) from e

    try:
        dist = get_or_create_district(db, gov.id, dist_name)
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات اللواء/القضاء.",
        ) from e

    try:
        area = get_or_create_area(db, gov.id, dist.id, area_name)
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات المنطقة (البلدة/الحي).",
        ) from e

    location_obj: Optional[models.Location] = None
    if loc_name:
        try:
            location_obj = (
                db.query(models.Location)
                .filter(
                    models.Location.area_id == area.id,
                    models.Location.name_ar == loc_name,
                )
                .first()
            )
            if not location_obj:
                location_obj = models.Location(area_id=area.id, name_ar=loc_name, longitude=lon, latitude=lat, is_active=1)
                db.add(location_obj)
                db.commit()
                db.refresh(location_obj)
        except SQLAlchemyError:
            db.rollback()
            location_obj = None

    location_point = None
    if location_obj:
        location_point = LocationPoint(
            id=location_obj.id,
            name_ar=location_obj.name_ar,
            latitude=getattr(location_obj, "latitude", None),
            longitude=getattr(location_obj, "longitude", None),
        )

    return ResolveLocationResponse(
        government=LocationInfo(id=gov.id, name_ar=gov.name_ar, name_en=getattr(gov, "name_en", None)),
        district=LocationInfo(id=dist.id, name_ar=dist.name_ar, name_en=getattr(dist, "name_en", None)),
        area=LocationInfo(id=area.id, name_ar=area.name_ar, name_en=getattr(area, "name_en", None)),
        location=location_point,
    )


def generate_text_suggestions(
    report_type_code: str,
    report_type_name_ar: str,
    gov_name_ar: str,
    dist_name_ar: str,
    area_name_ar: str,
) -> Tuple[str, str]:
    location_text = f"في منطقة {area_name_ar} / {dist_name_ar} / {gov_name_ar}"

    if report_type_code == "CONSTRUCTION_ROAD":
        title = "بلاغ عن أعمال إنشاء طرق"
        desc = (
            f"توجد أعمال إنشاء أو صيانة طرق {location_text} "
            "قد تسبب إزعاجاً أو خطراً للمارة والمركبات. نرجو تنظيم الموقع ووضع لوحات تحذيرية واضحة ومعالجة التشوه البصري."
        )
    elif report_type_code == "BAD_BILLBOARD":
        title = "بلاغ عن لوحة إعلانية مخالِفة"
        desc = (
            f"توجد لوحة إعلانية مخالِفة أو مشوِّهة للمظهر العام {location_text}. "
            "نرجو مراجعة وضع اللوحة، والتأكد من التزامها بالأنظمة وإزالة أو تعديل اللوحة عند الحاجة."
        )
    elif report_type_code == "GARBAGE":
        title = "بلاغ عن نفايات وتشوه بصري"
        desc = (
            f"يوجد تراكم للنفايات أو مخلفات متناثرة {location_text}. "
            "نرجو إزالة النفايات وتنظيف الموقع وتحسين النظافة العامة."
        )
    elif report_type_code == "GRAFFITI":
        title = "بلاغ عن كتابات جدارية (غرافيتي)"
        desc = (
            f"توجد كتابات جدارية (غرافيتي) أو رسومات غير مناسبة {location_text}. "
            "نرجو إزالة الكتابات وتنظيف الجدران بما يحافظ على المظهر الحضاري."
        )
    elif report_type_code == "CLUTTER_SIDEWALK":
        title = "بلاغ عن عوائق على الرصيف"
        desc = (
            f"يوجد رصيف مليء بالعوائق أو المخلفات {location_text} "
            "مما يعيق حركة المشاة ويؤثر على سلامتهم. نرجو إزالة العوائق وتنظيم الرصيف."
        )
    elif report_type_code == "POTHOLES":
        title = "بلاغ عن حفر في الطريق"
        desc = (
            f"توجد حفر أو تلف في سطح الطريق {location_text} "
            "مما يعرض المركبات والمارة للخطر. نرجو صيانة الطريق ومعالجة الحفر في أسرع وقت."
        )
    elif report_type_code == "SAND_ON_ROAD":
        title = "بلاغ عن رمال على الطريق"
        desc = (
            f"يوجد تراكم للرمال أو الأتربة على الطريق {location_text} "
            "مما قد يسبب انزلاق المركبات ويؤثر على الرؤية. نرجو إزالة الرمال وتنظيف الطريق."
        )
    elif report_type_code == "UNKEPT_FACADE":
        title = "بلاغ عن واجهة مبنى مهملة"
        desc = (
            f"توجد واجهة مبنى مهملة أو متضررة {location_text}. "
            "نرجو صيانة أو تجديد الواجهة لتحسين المظهر الجمالي للمنطقة."
        )
    elif report_type_code == "FADED_SIGNAGE":
        title = "بلاغ عن لافتات باهتة"
        desc = (
            f"توجد لافتة أو أكثر باهتة وغير واضحة {location_text}. "
            "نرجو إعادة طلائها أو استبدالها لتحسين وضوح المعلومات على الطريق."
        )
    elif report_type_code == "BROKEN_SIGNAGE":
        title = "بلاغ عن لافتات مكسورة"
        desc = (
            f"توجد لافتة طريق أو لوحة إرشادية مكسورة {location_text}. "
            "نرجو إصلاح أو استبدال اللافتة للحفاظ على سلامة مستخدمي الطريق."
        )
    else:
        title = "بلاغ عن تشوه بصري"
        desc = (
            f"هناك تشوه بصري أو مشكلة في المظهر العام {location_text}. "
            "نرجو التحقق من المشكلة ومعالجتها من قبل الجهة المختصة."
        )

    return title, desc


async def ai_analyze_image(
    file: UploadFile = File(...),
    gov_id: int = 0,
    dist_id: int = 0,
    area_id: int = 0,
    db: Session = Depends(get_db),
    clf: ReportClassifierService = Depends(get_classifier_service),
) -> AnalyzeImageResponse:
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ملف الصورة فارغ.",
        )

    try:
        report_type_id, confidence, info = clf.predict(image_bytes)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء تحليل الصورة.",
        ) from e

    gov = db.get(models.Government, gov_id) if gov_id else None
    dist = db.get(models.District, dist_id) if dist_id else None
    area = db.get(models.Area, area_id) if area_id else None

    gov_name_ar = gov.name_ar if gov else "غير محدد"
    dist_name_ar = dist.name_ar if dist else "غير محدد"
    area_name_ar = area.name_ar if area else "غير محدد"

    report_type_name_ar = info.get("name_ar", OTHERS_NAME_AR)
    report_type_code = info.get("code", OTHERS_CODE)
    model_class_id = info.get("model_class_id")

    if confidence < CONFIDENCE_THRESHOLD:
        report_type_id = OTHERS_REPORT_TYPE_ID
        report_type_name_ar = OTHERS_NAME_AR
        report_type_code = OTHERS_CODE

    suggested_title, suggested_description = generate_text_suggestions(
        report_type_code,
        report_type_name_ar,
        gov_name_ar,
        dist_name_ar,
        area_name_ar,
    )

    return AnalyzeImageResponse(
        report_type_id=report_type_id,
        report_type_name_ar=report_type_name_ar,
        confidence=confidence,
        class_id=model_class_id,
        class_name=report_type_code,
        suggested_title=suggested_title,
        suggested_description=suggested_description,
    )


async def debug_reverse_geo(payload: ResolveLocationRequest):
    geo = await reverse_geocode(payload.latitude, payload.longitude)
    return geo
