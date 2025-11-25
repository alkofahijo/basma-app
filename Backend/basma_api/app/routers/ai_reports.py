from __future__ import annotations

from typing import Optional, Tuple, Dict, Any

import httpx
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db import get_db  # returns a database Session
from app import models  # SQLAlchemy models
from app.ml.report_classifier import ReportClassifierService

router = APIRouter(prefix="/ai", tags=["AI"])

# ============================================================
# MODEL / CLASSIFIER SETUP
# ============================================================

# Load the classification model once (singleton pattern)
classifier_service: Optional[ReportClassifierService] = None

# Confidence threshold: if below this, classify as "OTHERS"
CONFIDENCE_THRESHOLD = 0.2

# Path to the local YOLOv8 model file
MODEL_PATH = "app/models/best.pt"

# ثابت لمعرّف "OTHERS" في قاعدة البيانات
# تأكد أن هذا يطابق السجل في جدول report_types
OTHERS_REPORT_TYPE_ID = 11


def get_classifier_service() -> ReportClassifierService:
    """
    Returns a singleton instance of ReportClassifierService.
    This service uses a local YOLOv8 model to classify visual pollution.
    """
    global classifier_service
    if classifier_service is None:
        classifier_service = ReportClassifierService(model_path=MODEL_PATH)
    return classifier_service


# ============================================================
# SCHEMAS
# ============================================================


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
    # Optional fields for debug info (class index and code from model)
    class_id: Optional[int] = None
    class_name: Optional[str] = Field(None, alias="class")
    suggested_title: str
    suggested_description: str


# ============================================================
# HELPERS: Reverse Geocoding & Name Cleaning
# ============================================================


async def reverse_geocode(lat: float, lon: float) -> Dict[str, Any]:
    """
    Use Nominatim (OpenStreetMap) to reverse geocode coordinates into an address.
    """
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
    """
    Clean up the governorate/district name by removing English words like
    "Governorate", "District", "Municipality".
    (Keeps Arabic text as-is to match DB entries.)
    """
    if not value:
        return ""
    value = value.strip()
    for token in ["Governorate", "District", "Municipality"]:
        value = value.replace(token, "")
    return value.strip()


def _clean_area_name(value: str) -> str:
    """
    Clean up the area name by removing generic Arabic terms like "ناحية", "لواء",
    "قضاء", "بلدية", "مدينة" for consistency.
    """
    if not value:
        return ""
    value = value.strip()
    for token in ["ناحية", "لواء", "قضاء", "بلدية", "مدينة"]:
        value = value.replace(token, "")
    # Remove extra whitespace
    return " ".join(value.split())


def extract_components(geo: Dict[str, Any]) -> Tuple[str, str, str, str]:
    """
    Extract relevant address components from Nominatim response:
      - gov_name: from address["state"]
      - dist_name: from address["state_district"] or fallback to address["county"]
      - area_name: from one of (village, neighbourhood, suburb, city, county)
      - loc_name: the full display_name of the location
    """
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


# ============================================================
# Endpoint: Resolve Location
# ============================================================


@router.post("/resolve-location", response_model=ResolveLocationResponse)
async def ai_resolve_location(
    payload: ResolveLocationRequest,
    db: Session = Depends(get_db),
):
    """
    يأخذ إحداثيات (lat/lon) ويستخدم Nominatim لتحديد:
      - المحافظة (governments)
      - اللواء / القضاء (districts)
      - المنطقة (areas)
      - الموقع التفصيلي (locations) إن وُجد
    ويقوم بإنشاء السجلات تلقائياً في قاعدة البيانات عند عدم وجودها.
    """
    lat = payload.latitude
    lon = payload.longitude

    # Reverse geocode the coordinates to get location names
    geo = await reverse_geocode(lat, lon)
    gov_raw, dist_raw, area_raw, loc_raw = extract_components(geo)

    gov_name = _clean_admin_name(gov_raw)
    dist_name = _clean_admin_name(dist_raw)
    area_name = _clean_area_name(area_raw)
    loc_name = loc_raw.strip() if loc_raw else ""

    print(
        "AI Resolve Location →",
        "gov:",
        gov_name,
        "| dist:",
        dist_name,
        "| area(raw):",
        area_raw,
        "| area(clean):",
        area_name,
        "| loc(display_name):",
        (loc_name[:80] + "..." if len(loc_name) > 80 else loc_name),
    )

    if not gov_name or not dist_name:
        # If we could not determine a governorate or district, return error
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="غير قادر على تحديد المحافظة أو اللواء من الإحداثيات.",
        )
    if not area_name:
        area_name = "منطقة بدون اسم"  # Default name if area is undefined

    # --------- Ensure Government exists in DB ---------
    try:
        gov = (
            db.query(models.Government)
            .filter(models.Government.name_ar == gov_name)
            .first()
        )
        if not gov:
            # Create a new government entry if not found
            print("Creating new Government:", gov_name)
            db.execute(
                text(
                    "INSERT INTO governments (name_ar, name_en, is_active) "
                    "VALUES (:name_ar, :name_en, 1)"
                ),
                {"name_ar": gov_name, "name_en": gov_name},
            )
            db.commit()
            gov = (
                db.query(models.Government)
                .filter(models.Government.name_ar == gov_name)
                .first()
            )
        if not gov:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="فشل إنشاء أو قراءة بيانات المحافظة من قاعدة البيانات.",
            )
    except SQLAlchemyError as e:
        db.rollback()
        print("Error while creating Government:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات المحافظة.",
        ) from e

    # --------- Ensure District exists in DB ---------
    try:
        dist = (
            db.query(models.District)
            .filter(
                models.District.government_id == gov.id,
                models.District.name_ar == dist_name,
            )
            .first()
        )
        if not dist:
            print("Creating new District:", dist_name, "for gov_id:", gov.id)
            # ✅ إضافة name_en في الإدخال لتفادي خطأ NOT NULL
            db.execute(
                text(
                    "INSERT INTO districts (government_id, name_ar, name_en, is_active) "
                    "VALUES (:gid, :name_ar, :name_en, 1)"
                ),
                {
                    "gid": gov.id,
                    "name_ar": dist_name,
                    "name_en": dist_name,
                },
            )
            db.commit()
            dist = (
                db.query(models.District)
                .filter(
                    models.District.government_id == gov.id,
                    models.District.name_ar == dist_name,
                )
                .first()
            )
        if not dist:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="فشل إنشاء أو قراءة بيانات اللواء/القضاء من قاعدة البيانات.",
            )
    except SQLAlchemyError as e:
        db.rollback()
        print("Error while creating District:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات اللواء/القضاء.",
        ) from e

    # --------- Ensure Area exists in DB ---------
    try:
        area = (
            db.query(models.Area)
            .filter(
                models.Area.district_id == dist.id,
                models.Area.name_ar == area_name,
            )
            .first()
        )
        if not area:
            print(
                "Creating new Area:",
                area_name,
                "| gov_id:",
                gov.id,
                "| district_id:",
                dist.id,
            )
            # سبق وأصلحناها: إضافة government_id + name_en
            db.execute(
                text(
                    "INSERT INTO areas (government_id, district_id, name_ar, name_en, is_active) "
                    "VALUES (:gid, :did, :name_ar, :name_en, 1)"
                ),
                {
                    "gid": gov.id,
                    "did": dist.id,
                    "name_ar": area_name,
                    "name_en": area_name,
                },
            )
            db.commit()
            area = (
                db.query(models.Area)
                .filter(
                    models.Area.district_id == dist.id,
                    models.Area.name_ar == area_name,
                )
                .first()
            )
        if not area:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="فشل إنشاء أو قراءة بيانات المنطقة من قاعدة البيانات.",
            )
    except SQLAlchemyError as e:
        db.rollback()
        print("Error while creating Area:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء حفظ بيانات المنطقة (البلدة/الحي).",
        ) from e

    # --------- Ensure Location exists in DB (optional detailed location) ---------
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
                print(
                    "Creating new Location:",
                    loc_name[:80] + ("..." if len(loc_name) > 80 else ""),
                    "| area_id:",
                    area.id,
                    "| lat/lon:",
                    lat,
                    lon,
                )
                db.execute(
                    text(
                        "INSERT INTO locations "
                        "(area_id, name_ar, longitude, latitude, is_active) "
                        "VALUES (:aid, :name_ar, :lon, :lat, 1)"
                    ),
                    {"aid": area.id, "name_ar": loc_name, "lon": lon, "lat": lat},
                )
                db.commit()
                location_obj = (
                    db.query(models.Location)
                    .filter(
                        models.Location.area_id == area.id,
                        models.Location.name_ar == loc_name,
                    )
                    .first()
                )
        except SQLAlchemyError as e:
            db.rollback()
            print("Error while creating Location:", e)
            location_obj = None

    # Prepare the response with the resolved location info
    location_point = None
    if location_obj:
        location_point = LocationPoint(
            id=location_obj.id,
            name_ar=location_obj.name_ar,
            latitude=getattr(location_obj, "latitude", None),
            longitude=getattr(location_obj, "longitude", None),
        )

    return ResolveLocationResponse(
        government=LocationInfo(
            id=gov.id,
            name_ar=gov.name_ar,
            name_en=getattr(gov, "name_en", None),
        ),
        district=LocationInfo(
            id=dist.id,
            name_ar=dist.name_ar,
            name_en=getattr(dist, "name_en", None),
        ),
        area=LocationInfo(
            id=area.id,
            name_ar=area.name_ar,
            name_en=getattr(area, "name_en", None),
        ),
        location=location_point,
    )


# ============================================================
# Helper: Generate Suggested Title/Description
# ============================================================


def generate_text_suggestions(
    report_type_code: str,
    report_type_name_ar: str,
    gov_name_ar: str,
    dist_name_ar: str,
    area_name_ar: str,
) -> Tuple[str, str]:
    """
    Generate a suggested report title and description in Arabic based on the
    report type code and location. Uses the Arabic name for the report type.
    """
    location_text = f"في منطقة {area_name_ar} / {dist_name_ar} / {gov_name_ar}"

    if report_type_code == "GRAFFITI":
        title = "بلاغ عن كتابة على الجدران"
        desc = (
            f"توجد كتابة على الجدران أو رسومات غرافيتي {location_text}. "
            "نرجو إزالة الكتابات وتنظيف الجدران لتحسين المظهر العام."
        )
    elif report_type_code == "FADED_SIGNAGE":
        title = "بلاغ عن لافتة باهتة"
        desc = (
            f"توجد لافتة طريق باهتة أو لوحة إرشادية متآكلة {location_text}. "
            "نرجو إعادة طلائها أو استبدالها لتحسين وضوح المعلومات."
        )
    elif report_type_code == "POTHOLES":
        title = "بلاغ عن حفر في الشارع"
        desc = (
            f"توجد حفر أو تلف في سطح الطريق {location_text} "
            "مما يعرض المركبات والمارة للخطر. نرجو صيانة الطريق ومعالجة الحفر."
        )
    elif report_type_code == "GARBAGE":
        title = "بلاغ عن نفايات وتشوه بصري"
        desc = (
            f"يوجد تراكم للنفايات أو مخلفات متناثرة {location_text}. "
            "نرجو إزالة النفايات وتنظيف الموقع لتحسين المظهر العام."
        )
    elif report_type_code == "CONSTRUCTION_ROAD":
        title = "بلاغ عن طريق قيد الإنشاء"
        desc = (
            f"يوجد طريق قيد الإنشاء أو أعمال حفريات {location_text} "
            "قد تسبب إزعاجاً أو خطراً للمارة. نرجو تأمين الموقع ووضع لوحات تحذيرية واضحة."
        )
    elif report_type_code == "BROKEN_SIGNAGE":
        title = "بلاغ عن لافتة مكسورة"
        desc = (
            f"توجد لافتة طريق أو لوحة إرشادية مكسورة {location_text}. "
            "نرجو إصلاح أو استبدال اللافتة للحفاظ على سلامة الطريق."
        )
    elif report_type_code == "BAD_BILLBOARD":
        title = "بلاغ عن لوحة إعلانات تالفة"
        desc = (
            f"توجد لوحة إعلانات تالفة أو مهملة {location_text}. "
            "نرجو صيانة اللوحة أو إزالتها إذا كانت غير صالحة لتحسين المنظر العام."
        )
    elif report_type_code == "SAND_ON_ROAD":
        title = "بلاغ عن تراكم أتربة على الطريق"
        desc = (
            f"يوجد تراكم للأتربة أو الرمال على الطريق {location_text} "
            "مما قد يسبب انزلاق المركبات. نرجو إزالة الأتربة وتنظيف الطريق."
        )
    elif report_type_code == "CLUTTER_SIDEWALK":
        title = "بلاغ عن رصيف غير صالح للمشي"
        desc = (
            f"يوجد رصيف مليء بالعوائق أو المخلفات {location_text} "
            "مما يعيق حركة المشاة. نرجو تنظيف الرصيف وإزالة العوائق."
        )
    elif report_type_code == "UNKEPT_FACADE":
        title = "بلاغ عن واجهة مبنى مشوهة"
        desc = (
            f"توجد واجهة مبنى سيئة المظهر أو متضررة {location_text}. "
            "نرجو تجديد الواجهة لتحسين المظهر الجمالي للمنطقة."
        )
    else:
        # Default case for unknown or "OTHERS"
        title = "بلاغ عن تشوه بصري"
        desc = (
            f"هناك تشوه بصري أو مشكلة في المظهر العام {location_text}. "
            "نرجو التحقق من المشكلة ومعالجتها من قبل الجهة المختصة."
        )

    return title, desc


# ============================================================
# Endpoint: Analyze Image
# ============================================================


@router.post("/analyze-image", response_model=AnalyzeImageResponse)
async def ai_analyze_image(
    file: UploadFile = File(...),
    gov_id: int = 0,
    dist_id: int = 0,
    area_id: int = 0,
    db: Session = Depends(get_db),
    clf: ReportClassifierService = Depends(get_classifier_service),
):
    """
    يقبل صورة من المستخدم ويستخدم نموذج YOLOv8 لتحليلها،
    ويرجع نوع التشوه البصري المتوقع مع درجة الثقة
    بالإضافة إلى عنوان ووصف مقترحين للبلاغ.
    """
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ملف الصورة فارغ.",
        )

    # Run the classifier on the image
    try:
        report_type_id, confidence, info = clf.predict(image_bytes)
    except Exception as e:
        print("AI analyze-image error:", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="حدث خطأ أثناء تحليل الصورة.",
        ) from e

    # Retrieve location names (Arabic) if IDs are provided
    gov = db.get(models.Government, gov_id) if gov_id else None
    dist = db.get(models.District, dist_id) if dist_id else None
    area = db.get(models.Area, area_id) if area_id else None

    gov_name_ar = gov.name_ar if gov else "غير محدد"
    dist_name_ar = dist.name_ar if dist else "غير محدد"
    area_name_ar = area.name_ar if area else "غير محدد"

    # Extract classification info
    report_type_name_ar = info.get("name_ar", "أخرى")
    report_type_code = info.get("code", "OTHERS")
    model_class_id = info.get("model_class_id")

    # If confidence is below threshold, override to "OTHERS"
    if confidence < CONFIDENCE_THRESHOLD:
        print(
            f"[AI] Low confidence ({confidence:.3f}) → mapping to OTHERS (id={OTHERS_REPORT_TYPE_ID}). "
            f"Original prediction: {report_type_code}"
        )
        report_type_id = OTHERS_REPORT_TYPE_ID
        report_type_name_ar = "أخرى"
        report_type_code = "OTHERS"
        model_class_id = OTHERS_REPORT_TYPE_ID

    # Generate suggested report title and description based on type and location
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


# ============================================================
# Debug endpoint: raw reverse geocoding (for development)
# ============================================================


@router.post("/debug-reverse-geo")
async def debug_reverse_geo(payload: ResolveLocationRequest):
    """
    Debug endpoint: returns raw reverse geocoding result (for development use only).
    """
    geo = await reverse_geocode(payload.latitude, payload.longitude)
    print("=== RAW GEO ===")
    import json

    print(json.dumps(geo, ensure_ascii=False, indent=2))
    print("=== END RAW GEO ===")
    return geo
