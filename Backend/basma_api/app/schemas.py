from __future__ import annotations
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, ConfigDict, model_validator

# ---------- Auth ----------
class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"

# ---------- Common ----------
class GovernmentOut(BaseModel):
    id: int
    name_ar: str
    name_en: str
    model_config = ConfigDict(from_attributes=True)

class DistrictOut(BaseModel):
    id: int
    government_id: int
    name_ar: str
    name_en: str
    model_config = ConfigDict(from_attributes=True)

class AreaOut(BaseModel):
    id: int
    district_id: int
    name_ar: str
    name_en: str
    model_config = ConfigDict(from_attributes=True)

class LocationOut(BaseModel):
    id: int
    area_id: int
    name_ar: str
    name_en: str
    longitude: Optional[float] = None
    latitude: Optional[float] = None
    model_config = ConfigDict(from_attributes=True)

# ---------- Citizens ----------
class CitizenCreate(BaseModel):
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    username: str
    password: str

class CitizenOut(BaseModel):
    id: int
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    model_config = ConfigDict(from_attributes=True)

# ---------- Initiatives ----------
class InitiativeCreate(BaseModel):
    name_ar: str
    name_en: str
    mobile_number: str
    join_form_link: Optional[str] = None
    government_id: int
    logo_url: Optional[str] = None
    username: str
    password: str

class InitiativeOut(BaseModel):
    id: int
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    model_config = ConfigDict(from_attributes=True)

# ---------- Reports ----------
class ReportTypeOut(BaseModel):
    id: int
    code: str
    name_ar: str
    name_en: str
    model_config = ConfigDict(from_attributes=True)

class ReportStatusOut(BaseModel):
    id: int
    code: str
    name_ar: str
    name_en: str
    model_config = ConfigDict(from_attributes=True)

# NEW: free-typed location creation payload
class NewLocationIn(BaseModel):
    area_id: int
    name_ar: str
    name_en: str
    longitude: Optional[float] = None
    latitude: Optional[float] = None

class ReportCreate(BaseModel):
    report_type_id: int
    name_ar: str
    name_en: str
    description_ar: str
    description_en: str
    note: Optional[str] = None

    government_id: int
    district_id: int
    area_id: int

    # EITHER provide location_id OR provide new_location (not both)
    location_id: Optional[int] = None
    new_location: Optional[NewLocationIn] = None

    reported_by_name: Optional[str] = None
    image_before_url: str  # set after upload

    @model_validator(mode="after")
    def validate_location_choice(self):
        has_id = self.location_id is not None
        has_new = self.new_location is not None
        if has_id == has_new:
            # both True or both False
            raise ValueError("Provide exactly one of: location_id OR new_location")
        # safety: area consistency if new_location provided
        if self.new_location and self.new_location.area_id != self.area_id:
            raise ValueError("new_location.area_id must match area_id")
        return self

class ReportOut(BaseModel):
    id: int
    report_code: str
    report_type_id: int
    name_ar: str
    name_en: str
    description_ar: str
    description_en: str
    note: Optional[str]
    image_before_url: str
    image_after_url: Optional[str]
    status_id: int
    reported_at: datetime
    adopted_by_id: Optional[int]
    adopted_by_type: Optional[Literal["initiative", "citizen"]]
    government_id: int
    district_id: int
    area_id: int
    location_id: int
    user_id: Optional[int]
    reported_by_name: Optional[str]
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

class ReportFilter(BaseModel):
    area_id: Optional[int] = None
    status_code: Optional[str] = None  # 'open' | 'completed' etc.

class AdoptRequest(BaseModel):
    adopted_by_type: Literal["initiative", "citizen"]
    adopted_by_id: int

class CompleteRequest(BaseModel):
    image_after_url: str
