# app/routers/ai_reports.py
from typing import Optional, Tuple, Dict, Any

import httpx
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db import get_db  # دالة ترجع Session
from app import models  # SQLAlchemy models
from app.ml.report_classifier import ReportClassifierService

router = APIRouter(prefix="/ai", tags=["AI"])

# نحمّل الـ model عند تشغيل التطبيق (in-memory singleton)
classifier_service: Optional[ReportClassifierService] = None


def get_classifier_service() -> ReportClassifierService:
    """
    إرجاع خدمة تصنيف البلاغات (singleton)
    """
    global classifier_service
    if classifier_service is None:
        classifier_service = ReportClassifierService(
            model_path="app/models/report_classifier.pt"
        )
    return classifier_service


# ---------- Schemas ----------


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
    suggested_title: str
    suggested_description: str


# ---------- Helpers: Reverse Geocoding & Names ----------


async def reverse_geocode(lat: float, lon: float) -> Dict[str, Any]:
    """
    استعلام reverse geocoding من Nominatim (OpenStreetMap).
    """
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "format": "json",
        "lat": lat,
        "lon": lon,
        "zoom": 16,
        "addressdetails": 1,
        "accept-language": "ar,en",  # نحاول نرجّع عربي قدر الإمكان
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
        # خطأ من خدمة تحديد الموقع
        raise HTTPException(
            status_code=502,
            detail="خدمة تحديد الموقع الجغرافي غير متاحة حالياً.",
        ) from e


def _clean_admin_name(value: str) -> str:
    """
    تنظيف بسيط لاسم المحافظة/اللواء (إزالة كلمات إنجليزية مثل Governorate, District).
    نترك العربية كما هي حتى لا نكسر أسماء الألوية عندك في DB.
    """
    if not value:
        return ""
    value = value.strip()

    remove_tokens = [
        "Governorate",
        "District",
        "Municipality",
    ]
    for t in remove_tokens:
        value = value.replace(t, "")
    value = value.strip()
    return value


def _clean_area_name(value: str) -> str:
    """
    تنظيف اسم المنطقة (area_name) بإزالة الكلمات العربية العامة مثل:
    ناحية، لواء، قضاء، بلدية، مدينة
    مع الإبقاء على باقي الكلمات.
    """
    if not value:
        return ""
    value = value.strip()

    remove_tokens = [
        "ناحية",
        "لواء",
        "قضاء",
        "بلدية",
        "مدينة",
    ]
    for t in remove_tokens:
        value = value.replace(t, "")

    # إزالة الفراغات الزائدة
    value = " ".join(value.split())
    return value


def extract_components(geo: Dict[str, Any]) -> Tuple[str, str, str, str]:
    """
    استخراج القيم بالضبط كما طلبت:

      gov_name   → من address["state"]          (مثال: إربد)
      dist_name  → من address["state_district"] (مثال: لواء قصبة إربد)
      area_name  → من address["county"]         (مثال: حوارة)
      loc_name   → من geo["display_name"]       (مثال: بشرى, حوارة, لواء قصبة إربد, إربد, 21141, الأردن)
    """
    address = geo.get("address", {}) or {}

    gov_name = address.get("state", "")  # المحافظة
    dist_name = address.get("state_district", "")  # اللواء / القضاء
    area_name = address.get("county", "")  # البلدة / المنطقة (مثل حوارة)
    loc_name = geo.get("display_name", "")  # نص كامل للموقع

    return gov_name or "", dist_name or "", area_name or "", loc_name or ""


# ---------- Endpoint: Resolve Location ----------


@router.post("/resolve-location", response_model=ResolveLocationResponse)
async def ai_resolve_location(
    payload: ResolveLocationRequest,
    db: Session = Depends(get_db),
):
    lat = payload.latitude
    lon = payload.longitude

    # استدعاء خدمة الـ reverse geocoding
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
        raise HTTPException(
            status_code=400,
            detail="غير قادر على تحديد المحافظة أو اللواء من الإحداثيات.",
        )

    if not area_name:
        area_name = "منطقة بدون اسم"

    # --------- Government: ابحث أو أنشئ (باستخدام SQL خام لضمان name_en) ---------
    try:
        gov = (
            db.query(models.Government)
            .filter(models.Government.name_ar == gov_name)
            .first()
        )

        if not gov:
            print("Creating new Government:", gov_name)
            # نفترض أن جدول governments فيه name_ar, name_en, is_active
            db.execute(
                text(
                    """
                    INSERT INTO governments (name_ar, name_en, is_active)
                    VALUES (:name_ar, :name_en, 1)
                    """
                ),
                {
                    "name_ar": gov_name,
                    "name_en": gov_name,
                },
            )
            db.commit()

            # إعادة القراءة عبر ORM
            gov = (
                db.query(models.Government)
                .filter(models.Government.name_ar == gov_name)
                .first()
            )

        if not gov:
            raise HTTPException(
                status_code=500,
                detail="فشل إنشاء أو قراءة بيانات المحافظة من قاعدة البيانات.",
            )

    except SQLAlchemyError as e:
        db.rollback()
        print("Error while creating Government:", e)
        raise HTTPException(
            status_code=500,
            detail="حدث خطأ أثناء حفظ بيانات المحافظة.",
        ) from e

    # --------- District: ابحث أو أنشئ (باستخدام SQL خام لضمان name_en) ---------
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
            db.execute(
                text(
                    """
                    INSERT INTO districts (government_id, name_ar, name_en, is_active)
                    VALUES (:government_id, :name_ar, :name_en, 1)
                    """
                ),
                {
                    "government_id": gov.id,
                    "name_ar": dist_name,
                    "name_en": dist_name,
                },
            )
            db.commit()

            # إعادة القراءة عبر ORM
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
                status_code=500,
                detail="فشل إنشاء أو قراءة بيانات اللواء/القضاء من قاعدة البيانات.",
            )

    except SQLAlchemyError as e:
        db.rollback()
        print("Error while creating District:", e)
        raise HTTPException(
            status_code=500,
            detail="حدث خطأ أثناء حفظ بيانات اللواء/القضاء.",
        ) from e

    # --------- Area (البلدة مثل حوارة): ابحث أو أنشئ ---------
    area = (
        db.query(models.Area)
        .filter(
            models.Area.district_id == dist.id,
            models.Area.name_ar == area_name,
        )
        .first()
    )

    if not area:
        try:
            print(
                "Creating new Area (town/village):",
                area_name,
                "| gov_id:",
                gov.id,
                "| district_id:",
                dist.id,
            )
            # NOTE: هنا SQL حسب سكيمتك الفعلية، عدّل الأعمدة لو DB مختلف
            db.execute(
                text(
                    """
                    INSERT INTO areas (government_id, district_id, name_ar, name_en)
                    VALUES (:government_id, :district_id, :name_ar, :name_en)
                    """
                ),
                {
                    "government_id": gov.id,
                    "district_id": dist.id,
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
        except SQLAlchemyError as e:
            db.rollback()
            print("Error while creating Area:", e)
            raise HTTPException(
                status_code=500,
                detail="حدث خطأ أثناء حفظ بيانات المنطقة (البلدة/القرية).",
            ) from e

    if not area:
        raise HTTPException(
            status_code=500,
            detail="فشل إنشاء أو قراءة بيانات المنطقة (Area) من قاعدة البيانات.",
        )

    # --------- Location (name_ar = display_name): ابحث أو أنشئ ---------
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
                    "Creating new Location (display_name):",
                    loc_name[:80] + ("..." if len(loc_name) > 80 else ""),
                    "| area_id:",
                    area.id,
                    "| lat/lon:",
                    lat,
                    lon,
                )
                db.execute(
                    text(
                        """
                        INSERT INTO locations (area_id, name_ar, longitude, latitude, is_active)
                        VALUES (:area_id, :name_ar, :lon, :lat, 1)
                        """
                    ),
                    {
                        "area_id": area.id,
                        "name_ar": loc_name,
                        "lon": lon,
                        "lat": lat,
                    },
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
            # لا نكسر الطلب كامل؛ فقط نرجع بدون location
            location_obj = None

    # --------- Response ---------

    location_response: Optional[LocationPoint] = None
    if location_obj:
        location_response = LocationPoint(
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
        location=location_response,
    )


# ---------- Helper: توليد عنوان ووصف مقترح ----------


def generate_text_suggestions(
    report_type_name_ar: str,
    gov_name_ar: str,
    dist_name_ar: str,
    area_name_ar: str,
) -> Tuple[str, str]:
    """
    توليد بسيط (rule-based) لعناوين ووصف، يمكن لاحقاً استبداله بنموذج لغوي.
    """
    location_text = f"في منطقة {area_name_ar} / {dist_name_ar} / {gov_name_ar}"

    if report_type_name_ar == "نظافة":
        title = "بلاغ عن مشكلة نظافة"
        desc = (
            f"يوجد تراكم للنفايات أو تشوه بصري متعلق بالنظافة {location_text}. "
            "نرجو معالجة المشكلة ورفع النفايات وتحسين مظهر المكان."
        )
    elif report_type_name_ar == "حُفر":
        title = "بلاغ عن حُفر في الشارع"
        desc = (
            f"توجد حُفر أو تلف في الشارع {location_text} "
            "مما يعرّض المركبات والمارة للخطر. نرجو صيانة الطريق."
        )
    elif report_type_name_ar == "أرصفة":
        title = "بلاغ عن مشكلة في الأرصفة"
        desc = (
            f"يوجد تلف أو عوائق في الأرصفة {location_text} "
            "مما يعيق حركة المشاة. نرجو صيانة وتحسين الأرصفة."
        )
    elif report_type_name_ar == "جدران":
        title = "بلاغ عن تشوه بصري في الجدران"
        desc = (
            f"يوجد تشوه بصري في الجدران {location_text} "
            "مثل كتابات عشوائية أو تلف في الجدار. نرجو معالجته."
        )
    elif report_type_name_ar == "زراعة":
        title = "بلاغ عن مشكلة في الزراعة والتشجير"
        desc = (
            f"يوجد نقص أو تلف في المساحات الخضراء أو الأشجار {location_text}. "
            "نرجو إعادة تشجير وتحسين المنظر العام."
        )
    else:  # أخرى
        title = "بلاغ عن تشوه بصري"
        desc = (
            f"يوجد تشوه بصري أو مشكلة عامة {location_text}. "
            "نرجو التحقق من البلاغ ومعالجة المشكلة."
        )

    return title, desc


# ---------- Endpoint: Analyze Image ----------


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
    يستقبل صورة من المستخدم، يمررها على نموذج التصنيف،
    ثم يرجّع:
      - نوع التشوه (report_type_id + الاسم بالعربي)
      - درجة الثقة
      - عنوان ووصف مقترحين حسب نوع البلاغ والموقع (إن وجد).
    """
    # تحميل الصورة كـ bytes
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="ملف الصورة فارغ.")

    # ML prediction
    try:
        report_type_id, confidence, info = clf.predict(image_bytes)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail="حدث خطأ أثناء تحليل الصورة.",
        ) from e

    # أخذ أسماء عربية للموقع (إن تم تمريرها)
    gov = db.query(models.Government).get(gov_id) if gov_id else None
    dist = db.query(models.District).get(dist_id) if dist_id else None
    area = db.query(models.Area).get(area_id) if area_id else None

    gov_name_ar = gov.name_ar if gov else "غير محدد"
    dist_name_ar = dist.name_ar if dist else "غير محدد"
    area_name_ar = area.name_ar if area else "غير محدد"

    # info["name_ar"] يفترض أن النموذج يرجع اسم نوع البلاغ بالعربي
    report_type_name_ar = info.get("name_ar", "أخرى")

    suggested_title, suggested_desc = generate_text_suggestions(
        report_type_name_ar,
        gov_name_ar,
        dist_name_ar,
        area_name_ar,
    )

    return AnalyzeImageResponse(
        report_type_id=report_type_id,
        report_type_name_ar=report_type_name_ar,
        confidence=confidence,
        suggested_title=suggested_title,
        suggested_description=suggested_desc,
    )


@router.post("/debug-reverse-geo")
async def debug_reverse_geo(
    payload: ResolveLocationRequest,
):
    """
    Endpoint ديبَغ: يرجّع الرد الخام من Nominatim كما هو.
    استخدمه فقط أثناء التطوير.
    """
    geo = await reverse_geocode(payload.latitude, payload.longitude)
    import json

    print("=== RAW GEO ===")
    print(json.dumps(geo, ensure_ascii=False, indent=2))
    print("=== END RAW GEO ===")
    return geo
