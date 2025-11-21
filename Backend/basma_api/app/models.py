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
    # name_en موجود في الجدول لكن لا نحتاجه حالياً للـ API
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))
    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    districts = relationship("District", back_populates="government")
    accounts = relationship("Account", back_populates="government")
    reports = relationship("Report", back_populates="government")

    def __repr__(self) -> str:
        return f"<Government id={self.id} name_ar={self.name_ar!r}>"


class District(Base):
    __tablename__ = "districts"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    government_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("governments.id"),
        nullable=False,
    )

    name_ar = Column(String(100), nullable=False)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    government = relationship("Government", back_populates="districts")
    areas = relationship("Area", back_populates="district")
    reports = relationship("Report", back_populates="district")

    def __repr__(self) -> str:
        return f"<District id={self.id} name_ar={self.name_ar!r}>"


class Area(Base):
    __tablename__ = "areas"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    district_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("districts.id"),
        nullable=False,
    )

    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=False)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    district = relationship("District", back_populates="areas")
    locations = relationship("Location", back_populates="area")
    reports = relationship("Report", back_populates="area")

    def __repr__(self) -> str:
        return f"<Area id={self.id} name_ar={self.name_ar!r}>"


class Location(Base):
    __tablename__ = "locations"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    area_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("areas.id"),
        nullable=False,
    )

    name_ar = Column(String(150), nullable=False)
    longitude = Column(Numeric(9, 6), nullable=True)
    latitude = Column(Numeric(9, 6), nullable=True)
    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    area = relationship("Area", back_populates="locations")
    reports = relationship("Report", back_populates="location")

    def __repr__(self) -> str:
        return f"<Location id={self.id} name_ar={self.name_ar!r}>"


# ============================================================
# ACCOUNTS & ACCOUNT TYPES (UNIFIED ACCOUNTS)
# ============================================================


class AccountType(Base):
    __tablename__ = "account_types"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=False)
    code = Column(String(50), nullable=True, unique=True)

    accounts = relationship("Account", back_populates="account_type")

    def __repr__(self) -> str:
        return f"<AccountType id={self.id} code={self.code!r}>"


class Account(Base):
    """
    حساب موحّد:
      - يمكن أن يمثّل: مبادرة، بلدية، شركة، ... حسب account_type_id
      - يتم الربط مع User (user_type=2) عبر account_id
      - ويتم اعتماده في التبنّي عبر adopted_by_account_id في Report
    """

    __tablename__ = "accounts"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)

    account_type_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("account_types.id"),
        nullable=False,
    )

    name_ar = Column(String(150), nullable=False)
    name_en = Column(String(200), nullable=False)

    mobile_number = Column(String(20), nullable=False, unique=True)

    government_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("governments.id"),
        nullable=False,
    )

    logo_url = Column(String(500), nullable=True)

    # رابط نموذج الانضمام (اختياري)
    join_form_link = Column(String(500), nullable=True)

    reports_completed_count = Column(
        MySQLInteger(unsigned=True),
        nullable=False,
        server_default=text("0"),
    )

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))
    # هل نعرض تفاصيل هذا الحساب في الواجهات العامة
    show_details = Column(SmallInteger, nullable=False, server_default=text("1"))

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    account_type = relationship("AccountType", back_populates="accounts")
    government = relationship("Government", back_populates="accounts")
    users = relationship("User", back_populates="account")
    adopted_reports = relationship(
        "Report",
        back_populates="adopted_by_account",
        foreign_keys="Report.adopted_by_account_id",
    )

    def __repr__(self) -> str:
        return f"<Account id={self.id} name_ar={self.name_ar!r}>"


# ============================================================
# USERS
# ============================================================


class User(Base):
    __tablename__ = "users"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    username = Column(String(150), nullable=False, unique=True)
    hashed_password = Column(String(255), nullable=False)

    # 1 = admin / super admin, 2 = normal (linked to account)
    user_type = Column(SmallInteger, nullable=False)

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))

    account_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("accounts.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    account = relationship("Account", back_populates="users")
    reports = relationship("Report", back_populates="user")

    def __repr__(self) -> str:
        return f"<User id={self.id} username={self.username!r}>"


# ============================================================
# REPORTS LOOKUPS
# ============================================================


class ReportType(Base):
    __tablename__ = "report_types"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    code = Column(String(50), nullable=False, unique=True)
    name_ar = Column(String(100), nullable=False)

    reports = relationship("Report", back_populates="report_type")

    def __repr__(self) -> str:
        return f"<ReportType id={self.id} code={self.code!r}>"


class ReportStatus(Base):
    __tablename__ = "report_status"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    code = Column(String(50), nullable=False, unique=True)
    name_ar = Column(String(100), nullable=False)

    reports = relationship("Report", back_populates="status")

    def __repr__(self) -> str:
        return f"<ReportStatus id={self.id} code={self.code!r}>"


# ============================================================
# REPORTS
# ============================================================


class Report(Base):
    __tablename__ = "reports"

    id = Column(MySQLInteger(unsigned=True), primary_key=True, autoincrement=True)
    report_code = Column(String(100), nullable=False, unique=True)

    report_type_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("report_types.id"),
        nullable=False,
    )

    name_ar = Column(String(200), nullable=False)

    description_ar = Column(MySQLMediumText(), nullable=False)
    note = Column(MySQLMediumText(), nullable=True)

    image_before_url = Column(String(500), nullable=False)
    image_after_url = Column(String(500), nullable=True)

    status_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("report_status.id"),
        nullable=False,
    )

    reported_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )

    # تبنّي موحّد: الحساب الذي تبنّى هذا البلاغ
    adopted_by_account_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("accounts.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    government_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("governments.id"),
        nullable=False,
    )

    district_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("districts.id"),
        nullable=False,
    )

    area_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("areas.id"),
        nullable=False,
    )

    location_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("locations.id"),
        nullable=False,
    )

    # المستخدم الذي سجّل البلاغ (لو موجود)
    user_id = Column(
        MySQLInteger(unsigned=True),
        ForeignKey("users.id", onupdate="RESTRICT", ondelete="SET NULL"),
        nullable=True,
    )

    # في حال البلاغ من زائر أو جهة بدون حساب
    reported_by_name = Column(String(200), nullable=True)

    is_active = Column(SmallInteger, nullable=False, server_default=text("1"))
    created_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at = Column(
        TIMESTAMP,
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
        onupdate=text("CURRENT_TIMESTAMP"),
    )

    report_type = relationship("ReportType", back_populates="reports")
    status = relationship("ReportStatus", back_populates="reports")
    government = relationship("Government", back_populates="reports")
    district = relationship("District", back_populates="reports")
    area = relationship("Area", back_populates="reports")
    location = relationship("Location", back_populates="reports")
    adopted_by_account = relationship(
        "Account",
        back_populates="adopted_reports",
        foreign_keys=[adopted_by_account_id],
    )
    user = relationship("User", back_populates="reports")

    def __repr__(self) -> str:
        return f"<Report id={self.id} code={self.report_code!r}>"
