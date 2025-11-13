from __future__ import annotations

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy import (
    Column,
    String,
    SmallInteger,
    TIMESTAMP,
    ForeignKey,
    Numeric,
    text,
)
from sqlalchemy.dialects.mysql import (
    INTEGER as MySQLInteger,
    MEDIUMTEXT as MySQLMediumText,
)

Base = declarative_base()

# ============================================================
# LOCATIONS
# ============================================================


class Government(Base):
    __tablename__ = "governments"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    name_ar = Column(String(100), nullable=False)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))
    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    districts = relationship("District", back_populates="government")


class District(Base):
    __tablename__ = "districts"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    government_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("governments.id"), nullable=False
    )

    name_ar = Column(String(100), nullable=False)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    government = relationship("Government", back_populates="districts")
    areas = relationship("Area", back_populates="district")


class Area(Base):
    __tablename__ = "areas"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    district_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("districts.id"), nullable=False
    )

    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=False)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    district = relationship("District", back_populates="areas")
    locations = relationship("Location", back_populates="area")


class Location(Base):
    __tablename__ = "locations"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    area_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("areas.id"), nullable=False
    )

    name_ar = Column(String(150), nullable=False)
    longitude = Column(Numeric(9, 6), nullable=True)
    latitude = Column(Numeric(9, 6), nullable=True)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    area = relationship("Area", back_populates="locations")


# ============================================================
# CITIZENS & INITIATIVES
# ============================================================


class Citizen(Base):
    __tablename__ = "citizens"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    name_ar = Column(String(150), nullable=False)
    mobile_number = Column(String(20), nullable=False, unique=True)

    government_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("governments.id"), nullable=False
    )

    reports_completed_count = Column(
        MySQLInteger(unsigned=True), nullable=False, server_default=text("0")
    )

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )


class Initiative(Base):
    __tablename__ = "initiatives"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    name_ar = Column(String(200), nullable=False)
    mobile_number = Column(String(20), nullable=False, unique=True)
    join_form_link = Column(String(500), nullable=True)

    government_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("governments.id"), nullable=False
    )

    logo_url = Column(String(500), nullable=True)
    members_count = Column(
        MySQLInteger(unsigned=True), nullable=False, server_default=text("0")
    )
    reports_completed_count = Column(
        MySQLInteger(unsigned=True), nullable=False, server_default=text("0")
    )

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )


class User(Base):
    __tablename__ = "users"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    username = Column(String(150), nullable=False, unique=True)
    hashed_password = Column(String(255), nullable=False)
    user_type = Column(SmallInteger, nullable=False)  # 1 admin, 2 initiative, 3 citizen
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    initiative_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("initiatives.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    citizen_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("citizens.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )


# ============================================================
# REPORTS LOOKUPS
# ============================================================


class ReportType(Base):
    __tablename__ = "report_types"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    code = Column(String(50), nullable=False, unique=True)
    name_ar = Column(String(100), nullable=False)


class ReportStatus(Base):
    __tablename__ = "report_status"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    code = Column(String(50), nullable=False, unique=True)
    name_ar = Column(String(100), nullable=False)


# ============================================================
# REPORTS
# ============================================================


class Report(Base):
    __tablename__ = "reports"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    report_code = Column(String(100), nullable=False, unique=True)

    report_type_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("report_types.id"), nullable=False
    )

    name_ar = Column(String(200), nullable=False)

    description_ar = Column(MySQLMediumText, nullable=False)
    note = Column(MySQLMediumText, nullable=True)

    image_before_url = Column(String(500), nullable=False)
    image_after_url = Column(String(500), nullable=True)

    status_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("report_status.id"), nullable=False
    )

    reported_at = Column(TIMESTAMP, server_default=text("CURRENT_TIMESTAMP"))

    # 🚨 IMPORTANT: integer not enum
    adopted_by_id = Column(MySQLInteger(unsigned=True), nullable=True)
    adopted_by_type = Column(
        MySQLInteger(unsigned=True), nullable=True
    )  # 1= citizen, 2= initiative

    government_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("governments.id"), nullable=False
    )

    district_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("districts.id"), nullable=False
    )

    area_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("areas.id"), nullable=False
    )

    location_id = Column(
        MySQLInteger(unsigned=True), ForeignKey("locations.id"), nullable=False
    )

    user_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("users.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    reported_by_name = Column(String(200), nullable=True)

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))
    created_at = Column(
        TIMESTAMP, nullable=False, server_default=text("CURRENT_TIMESTAMP")
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )
