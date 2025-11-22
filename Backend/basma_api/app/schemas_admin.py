# app/schemas_admin.py
from __future__ import annotations

from datetime import datetime
from typing import Optional, Annotated

from pydantic import BaseModel, ConfigDict, StringConstraints


# ============ AUTH ============

class AdminLoginRequest(BaseModel):
    username: Annotated[str, StringConstraints(min_length=1, max_length=150)]
    password: Annotated[str, StringConstraints(min_length=1, max_length=100)]


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ============ COMMON TYPES ============

Str150 = Annotated[str, StringConstraints(min_length=3, max_length=150)]
PasswordStr = Annotated[str, StringConstraints(min_length=6, max_length=100)]


# ============ USERS ============

class AdminUserBase(BaseModel):
    username: Str150
    is_active: int = 1
    user_type: int = 2   # default normal user


class AdminUserCreate(AdminUserBase):
    password: PasswordStr
    account_id: Optional[int] = None


class AdminUserUpdate(BaseModel):
    username: Optional[Str150] = None
    password: Optional[PasswordStr] = None
    is_active: Optional[int] = None
    user_type: Optional[int] = None
    account_id: Optional[int] = None


class AdminUserOut(BaseModel):
    id: int
    username: str
    user_type: int
    is_active: int
    account_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============ GOVERNMENTS (محافظات) ============

class GovernmentOut(BaseModel):
    """
    مخرجات الـ lookup الخاصة بالمحافظات.
    تُستخدم في:
      - /governments endpoint
      - الواجهات الأمامية كـ dropdown للمحافظة
    """
    id: int
    name_ar: str
    name_en: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# ============ ACCOUNTS ============

class AdminAccountCreate(BaseModel):
    account_type_id: int
    name_ar: Annotated[str, StringConstraints(min_length=1, max_length=150)]
    name_en: Annotated[str, StringConstraints(min_length=1, max_length=200)]
    mobile_number: Annotated[str, StringConstraints(min_length=3, max_length=20)]
    government_id: int
    logo_url: Optional[str] = None
    join_form_link: Optional[str] = None
    is_active: int = 1
    show_details: int = 1

    # optional user to be created for this account
    username: Optional[Str150] = None
    password: Optional[PasswordStr] = None


class AdminAccountUpdate(BaseModel):
    account_type_id: Optional[int] = None
    name_ar: Optional[str] = None
    name_en: Optional[str] = None
    mobile_number: Optional[str] = None
    government_id: Optional[int] = None
    logo_url: Optional[str] = None
    join_form_link: Optional[str] = None
    is_active: Optional[int] = None
    show_details: Optional[int] = None


class AdminAccountOut(BaseModel):
    id: int
    account_type_id: int
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    logo_url: Optional[str]
    join_form_link: Optional[str]
    reports_completed_count: int
    is_active: int
    show_details: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============ REPORTS ============

class AdminReportUpdate(BaseModel):
    report_type_id: Optional[int] = None
    name_ar: Optional[str] = None
    description_ar: Optional[str] = None
    note: Optional[str] = None
    image_before_url: Optional[str] = None
    image_after_url: Optional[str] = None
    status_id: Optional[int] = None
    adopted_by_account_id: Optional[int] = None
    government_id: Optional[int] = None
    district_id: Optional[int] = None
    area_id: Optional[int] = None
    location_id: Optional[int] = None
    is_active: Optional[int] = None


class AdminReportOut(BaseModel):
    id: int
    report_code: str
    report_type_id: int
    name_ar: str
    description_ar: str
    note: Optional[str]
    image_before_url: Optional[str]
    image_after_url: Optional[str]
    status_id: int
    adopted_by_account_id: Optional[int]
    government_id: int
    district_id: int
    area_id: int
    location_id: int
    user_id: Optional[int]
    reported_by_name: Optional[str]
    is_active: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
