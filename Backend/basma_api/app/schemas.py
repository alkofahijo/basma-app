from __future__ import annotations

from datetime import datetime
from typing import Optional, Literal

from pydantic import BaseModel, ConfigDict


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


# ============================================================
# CITIZEN
# ============================================================


class CitizenCreate(BaseModel):
    name_ar: str
    mobile_number: str
    government_id: int
    username: str
    password: str


class CitizenOut(BaseModel):
    id: int
    name_ar: str
    mobile_number: str
    government_id: int

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# INITIATIVE
# ============================================================


class InitiativeCreate(BaseModel):
    name_ar: str
    mobile_number: str
    join_form_link: Optional[str]
    government_id: int
    logo_url: Optional[str]
    username: str
    password: str


class InitiativeOut(BaseModel):
    id: int
    name_ar: str
    mobile_number: str
    government_id: int

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# REPORT LOOKUP
# ============================================================


class ReportTypeOut(BaseModel):
    id: int
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


class NewLocationCreate(BaseModel):
    area_id: int
    name_ar: str
    latitude: Optional[float]
    longitude: Optional[float]


class ReportCreate(BaseModel):
    report_type_id: int
    name_ar: str
    description_ar: str
    note: Optional[str] = None
    image_before_url: Optional[str] = None

    government_id: int
    district_id: int
    area_id: int

    location_id: Optional[int] = None
    new_location: Optional[NewLocationCreate] = None

    reported_by_name: Optional[str] = None


# ============================================================
# REPORT OUT
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

    adopted_by_type: Optional[int]  # 1 citizen, 2 initiative
    adopted_by_id: Optional[int]
    adopted_by_name: Optional[str] = None

    government_id: int
    district_id: int
    area_id: int
    location_id: int

    user_id: Optional[int]
    reported_by_name: Optional[str]

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# REPORT ACTION REQUESTS
# ============================================================


class AdoptRequest(BaseModel):
    adopted_by_type: Literal[1, 2]  # 1 citizen, 2 initiative
    adopted_by_id: int


class CompleteRequest(BaseModel):
    image_after_url: str
    note: Optional[str] = None
