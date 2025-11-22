from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, model_validator

# ============================================================
# AUTH
# ============================================================


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ============================================================
# LOCATIONS
# ============================================================


class GovernmentOut(BaseModel):
    id: int
    name_ar: str

    model_config = ConfigDict(from_attributes=True)


class DistrictOut(BaseModel):
    id: int
    government_id: int
    name_ar: str

    model_config = ConfigDict(from_attributes=True)


class AreaOut(BaseModel):
    id: int
    district_id: int
    name_ar: str
    name_en: str

    model_config = ConfigDict(from_attributes=True)


class AreaCreate(BaseModel):
    district_id: int
    name_ar: str
    name_en: str


class LocationOut(BaseModel):
    id: int
    area_id: int
    name_ar: str
    longitude: Optional[float]
    latitude: Optional[float]

    model_config = ConfigDict(from_attributes=True)


class LocationCreate(BaseModel):
    area_id: int
    name_ar: str
    latitude: float | None = None
    longitude: float | None = None


# ============================================================
# REPORT PUBLIC OUT (for /reports/public)
# ============================================================


class ReportPublicOut(BaseModel):
    id: int
    report_code: str

    report_type_id: int
    report_type_code: str
    report_type_name_ar: str

    name_ar: str
    description_ar: str | None = None

    image_before_url: str | None = None

    status_id: int
    status_name_ar: str
    reported_at: datetime | None = None

    government_id: int | None = None
    government_name_ar: str | None = None

    district_id: int | None = None
    district_name_ar: str | None = None

    area_id: int | None = None
    area_name_ar: str | None = None

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# ACCOUNTS (UNIFIED)
# ============================================================


class AccountTypeOut(BaseModel):
    id: int
    name_ar: str
    name_en: str
    code: str | None = None

    model_config = ConfigDict(from_attributes=True)


class AccountCreate(BaseModel):
    """
    لإنشاء حساب من لوحة التحكم (admin) – يمكن إرسال username/password أو تركهما.
    """

    account_type_id: int
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    logo_url: str | None = None
    join_form_link: str | None = None

    username: str | None = None
    password: str | None = None


class AccountRegister(BaseModel):
    """
    لتسجيل حساب جديد عبر /auth/register (كل شيء مطلوب).
    """

    account_type_id: int
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    logo_url: str | None = None
    join_form_link: str | None = None

    username: str
    password: str


class AccountOut(BaseModel):
    id: int

    account_type_id: int
    account_type_name_ar: str | None = None
    account_type_name_en: str | None = None
    account_type_code: str | None = None

    name_ar: str
    name_en: str
    mobile_number: str

    government_id: int
    government_name_ar: str | None = None

    logo_url: str | None = None
    join_form_link: str | None = None

    reports_completed_count: int
    is_active: int
    show_details: int

    created_at: datetime
    updated_at: datetime

    # العلاقات كاملة (nested) – مهمة للـ Flutter لو حب يقرأ منها مباشرة
    account_type: AccountTypeOut | None = None
    government: GovernmentOut | None = None

    model_config = ConfigDict(from_attributes=True)

    # ✅ تنظيف وملء الحقول المسطّحة من العلاقات لو كانت موجودة
    @model_validator(mode="after")
    def populate_flat_names_from_relations(self) -> "AccountOut":
        # من account_type
        if self.account_type is not None:
            if self.account_type_name_ar is None:
                self.account_type_name_ar = self.account_type.name_ar
            if self.account_type_name_en is None:
                self.account_type_name_en = self.account_type.name_en
            if self.account_type_code is None:
                self.account_type_code = self.account_type.code

        # من government
        if self.government is not None and self.government_name_ar is None:
            self.government_name_ar = self.government.name_ar

        return self


# ============================================================
# REPORT LOOKUP
# ============================================================

class AccountOptionOut(BaseModel):
    id: int
    name_ar: str

    model_config = ConfigDict(from_attributes=True)
    
class ReportTypeOut(BaseModel):
    id: int
    code: str
    name_ar: str

    model_config = ConfigDict(from_attributes=True)


class ReportStatusOut(BaseModel):
    id: int
    code: str
    name_ar: str

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# REPORT CREATE
# ============================================================


class ReportCreate(BaseModel):
    report_type_id: int
    name_ar: str
    description_ar: str
    note: Optional[str] = None
    image_before_url: Optional[str] = None

    government_id: int
    district_id: int
    area_id: int

    location_id: int | None = None
    new_location: LocationCreate | None = None

    # لو المبلّغ زائر بدون حساب
    reported_by_name: Optional[str] = None


# ============================================================
# REPORT OUT  (for /reports and /reports/{id})
# ============================================================


class ReportOut(BaseModel):
    id: int
    report_code: str
    report_type_id: int

    name_ar: str
    description_ar: str
    note: Optional[str]

    image_before_url: Optional[str]
    image_after_url: Optional[str]

    status_id: int
    reported_at: datetime

    # unified adoption via accounts
    adopted_by_account_id: Optional[int]
    adopted_by_account_name: Optional[str] = None

    government_id: int
    district_id: int
    area_id: int
    location_id: int

    user_id: Optional[int]
    reported_by_name: Optional[str]

    is_active: int

    created_at: datetime
    updated_at: datetime

    # Arabic names for foreign keys (JOIN output)
    report_type_name_ar: Optional[str] = None
    status_name_ar: Optional[str] = None
    government_name_ar: Optional[str] = None
    district_name_ar: Optional[str] = None
    area_name_ar: Optional[str] = None
    location_name_ar: Optional[str] = None

    # Coordinates of location
    location_longitude: Optional[float] = None
    location_latitude: Optional[float] = None

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# REPORT ACTION REQUESTS
# ============================================================


class AdoptRequest(BaseModel):
    """
    طلب تبنّي بلاغ.
    في التصميم الجديد الأفضل أن نعتمد على الحساب من الـ JWT مباشرة،
    لكن لو أردت استخدام body يمكنك تمرير account_id هنا.
    """
    account_id: int


class CompleteRequest(BaseModel):
    image_after_url: str
    note: Optional[str] = None
