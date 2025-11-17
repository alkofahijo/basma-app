# app/routers/ai_reports.py

from typing import Optional, Tuple, Dict, Any

import httpx
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db import get_db  # دالة ترجع Session
from app import models  # SQLAlchemy models
from app.ml.report_classifier import ReportClassifierService

router = APIRouter(prefix="/ai", tags=["AI"])

# نحمّل الـ model / الخدمة عند تشغيل التطبيق (in-memory singleton)
classifier_service: Optional[ReportClassifierService] = None

# Threshold للثقة (لو أقل → نعتبرها "أخرى")
CONFIDENCE_THRESHOLD = 0.6  # جرّب بين 0.5 و 0.7 حسب النتائج الفعلية

# إعدادات خادم الـ Inference (Roboflow)
INFERENCE_API_URL = "http://localhost:9001"
INFERENCE_API_KEY = "VnX7BllCuY4lmeCk4yDm"
INFERENCE_WORKSPACE_NAME = "ahmad-i1hsy"
INFERENCE_WORKFLOW_ID = "custom-workflow"


def get_classifier_service() -> ReportClassifierService:
    """
    إرجاع خدمة تصنيف البلاغات (singleton) التي تتصل بخادم Roboflow Inference
    وتنفّذ workflow مخصّص لإرجاع نوع التشوّه البصري.
    """
    global classifier_service
    if classifier_service is None:
        classifier_service = ReportClassifierService(
            api_url=INFERENCE_API_URL,
            api_key=INFERENCE_API_KEY,
            workspace_name=INFERENCE_WORKSPACE_NAME,
            workflow_id=INFERENCE_WORKFLOW_ID,
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
    # هذه الحقول اختيارية لإرجاع class_id و class كما في استجابة الـ workflow
    class_id: Optional[int] = None
    class_name: Optional[str] = Field(None, alias="class")
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

    remove_tokens = ["Governorate", "District", "Municipality"]
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

    remove_tokens = ["ناحية", "لواء", "قضاء", "بلدية", "مدينة"]
    for t in remove_tokens:
        value = value.replace(t, "")

    value = " ".join(value.split())
    return value


def extract_components(geo: Dict[str, Any]) -> Tuple[str, str, str, str]:
    """
    استخراج القيم من رد Nominatim:

      gov_name   → من address["state"]                (مثال: إربد)
      dist_name  → من address["state_district"]
                    أو fallback إلى address["county"] (مثال: لواء قصبة إربد)
      area_name  → أولوية:
                      1) address["village"]           (مثال: كفر سوم / المزار)
                      2) address["neighbourhood"]     (مثال: المنارة)
                      3) address["suburb"]
                      4) address["city"]
                      5) address["county"]
      loc_name   → من geo["display_name"]
    """
    address = geo.get("address", {}) or {}

    gov_name = address.get("state") or ""

    # لو موجود state_district نستخدمه، وإلا نحاول county
    dist_name = address.get("state_district") or address.get("county") or ""

    # أولوية استخراج اسم الحي/المنطقة
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


# ---------- Endpoint: Resolve Location ----------


@router.post("/resolve-location", response_model=ResolveLocationResponse)
async def ai_resolve_location(
    payload: ResolveLocationRequest,
    db: Session = Depends(get_db),
):
    lat = payload.latitude
    lon = payload.longitude

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

    # --------- Government ---------
    try:
        gov = (
            db.query(models.Government)
            .filter(models.Government.name_ar == gov_name)
            .first()
        )

        if not gov:
            print("Creating new Government:", gov_name)
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

    # --------- District ---------
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

    # --------- Area ---------
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
                "Creating new Area (town/village/neighbourhood):",
                area_name,
                "| gov_id:",
                gov.id,
                "| district_id:",
                dist.id,
            )
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
                detail="حدث خطأ أثناء حفظ بيانات المنطقة (البلدة/الحي).",
            ) from e

    if not area:
        raise HTTPException(
            status_code=500,
            detail="فشل إنشاء أو قراءة بيانات المنطقة (Area) من قاعدة البيانات.",
        )

    # --------- Location ---------
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
            location_obj = None

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
    report_type_code: str,
    report_type_name_ar: str,
    gov_name_ar: str,
    dist_name_ar: str,
    area_name_ar: str,
) -> Tuple[str, str]:
    """
    توليد عناوين وأوصاف مقترحة بناءً على code (GRAFFITI, POTHOLES, ...)
    مع استخدام الاسم العربي الجديد من جدولك.
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
            f"توجد لافتة طرق أو لوحة إرشادية باهتة يصعب قراءتها {location_text}. "
            "نرجو إعادة طلاء اللافتة أو استبدالها لتحسين وضوح المعلومات."
        )

    elif report_type_code == "POTHOLES":
        title = "بلاغ عن حفر في الشارع"
        desc = (
            f"توجد حفر أو تلف في سطح الطريق {location_text} "
            "مما يعرّض المركبات والمارة للخطر. نرجو صيانة الطريق ومعالجة الحفر."
        )

    elif report_type_code == "GARBAGE":
        title = "بلاغ عن نفايات وتشوه بصري"
        desc = (
            f"يوجد تراكم للنفايات أو مخلفات متناثرة {location_text}. "
            "نرجو إزالة النفايات وتنظيف الموقع وتحسين مظهر المنطقة."
        )

    elif report_type_code == "CONSTRUCTION_ROAD":
        title = "بلاغ عن طريق قيد الإنشاء"
        desc = (
            f"يوجد طريق قيد الإنشاء أو أعمال حفريات {location_text} "
            "قد تسبب إزعاجاً أو خطراً للمارة والمركبات. نرجو تنظيم الموقع "
            "وتأمينه ووضع لوحات تحذيرية واضحة."
        )

    elif report_type_code == "BROKEN_SIGNAGE":
        title = "بلاغ عن لافتة مكسورة"
        desc = (
            f"توجد لافتة طرق أو لوحة إرشادية مكسورة أو متضررة {location_text}. "
            "نرجو إصلاح اللافتة أو استبدالها للحفاظ على سلامة الطريق وشكل المدينة."
        )

    elif report_type_code == "BAD_STREETLIGHT":
        title = "بلاغ عن إنارة طريق تالفة"
        desc = (
            f"توجد أعمدة إنارة أو مصابيح تالفة أو لا تعمل {location_text}. "
            "نرجو إصلاح الإنارة لتحسين الرؤية ليلاً وتعزيز السلامة."
        )

    elif report_type_code == "BAD_BILLBOARD":
        title = "بلاغ عن لوحة إعلانات تالفة"
        desc = (
            f"توجد لوحة إعلانات تالفة أو مهملة {location_text}. "
            "نرجو صيانة اللوحة أو إزالتها إن كانت مهجورة لتحسين المنظر العام."
        )

    elif report_type_code == "SAND_ON_ROAD":
        title = "بلاغ عن أتربة على الطريق"
        desc = (
            f"يوجد تراكم للأتربة أو الرمال على سطح الطريق {location_text} "
            "مما قد يسبب انزلاق المركبات وخطر على السلامة. نرجو إزالة الأتربة وتنظيف الطريق."
        )

    elif report_type_code == "CLUTTER_SIDEWALK":
        title = "بلاغ عن رصيف غير صالح للمشي"
        desc = (
            f"يوجد رصيف غير صالح للمشي أو توجد عوائق ومخلفات على الرصيف {location_text} "
            "مما يعيق حركة المشاة، خاصة كبار السن وذوي الإعاقة. نرجو إزالة العوائق وتنظيم الرصيف."
        )

    elif report_type_code == "UNKEPT_FACADE":
        title = "بلاغ عن واجهة مبنى سيئة المظهر"
        desc = (
            f"توجد واجهة مبنى سيئة المظهر أو مهملة أو مليئة بالتشوهات البصرية {location_text}. "
            "نرجو صيانة الواجهة وتحسين مظهرها بما يليق بالمنطقة."
        )

    else:
        # كود غير متوقع أو "OTHERS" → نص عام
        title = "بلاغ عن تشوه بصري"
        desc = (
            f"يوجد تشوه بصري أو مشكلة في المظهر العام {location_text}. "
            "نرجو التحقق من البلاغ ومعالجة المشكلة حسب نوعها."
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
    يستقبل صورة من المستخدم، يرسلها إلى Roboflow Inference workflow لتحليلها،
    ثم يرجّع:
      - نوع التشوه (report_type_id + الاسم بالعربي)
      - درجة الثقة
      - عنوان ووصف مقترحين حسب نوع البلاغ والموقع (إن وجد).
    """
    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="ملف الصورة فارغ.")

    # ML prediction عبر خادم الـ Inference
    try:
        report_type_id, confidence, info = clf.predict(image_bytes)
    except Exception as e:
        print("AI analyze-image error:", e)
        raise HTTPException(
            status_code=500,
            detail="حدث خطأ أثناء تحليل الصورة.",
        ) from e

    # أسماء عربية للموقع (إن تم تمرير IDs)
    gov = db.query(models.Government).get(gov_id) if gov_id else None
    dist = db.query(models.District).get(dist_id) if dist_id else None
    area = db.query(models.Area).get(area_id) if area_id else None

    gov_name_ar = gov.name_ar if gov else "غير محدد"
    dist_name_ar = dist.name_ar if dist else "غير محدد"
    area_name_ar = area.name_ar if area else "غير محدد"

    # القيم الأساسية من الـ workflow
    report_type_name_ar = info.get("name_ar", "أخرى")
    report_type_code = info.get("code", "UNKNOWN")
    model_class_id = info.get("model_class_id")

    # -------- Threshold على الثقة --------
    # لو الثقة أقل من CONFIDENCE_THRESHOLD → نعتبرها "OTHERS" (id = 12 في DB)
    if confidence < CONFIDENCE_THRESHOLD:
        print(
            f"[AI] Low confidence ({confidence:.3f}) → mapping to OTHERS (id=12). "
            f"Original prediction: {report_type_code}"
        )
        report_type_id = 12  # OTHERS في جدول report_types
        report_type_name_ar = "أخرى"
        report_type_code = "OTHERS"
        model_class_id = 12

    suggested_title, suggested_desc = generate_text_suggestions(
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
