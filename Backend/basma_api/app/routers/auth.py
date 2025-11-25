from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import User, Account, Government, AccountType
from ..schemas import TokenOut
from ..security import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user_payload,
)
from ..controllers.auth_controller import (
    register_account as controller_register_account,
    login as controller_login,
    change_password as controller_change_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


# ============================================================
# REQUEST MODEL: CHANGE PASSWORD
# ============================================================

class ChangePasswordIn(BaseModel):
    new_password: str = Field(min_length=6)


# ============================================================
# REQUEST MODEL: REGISTER ACCOUNT (UNIFIED)
# ============================================================

class AccountRegisterIn(BaseModel):
    """
    تستخدم لتسجيل أي نوع من الحسابات (حسب account_type_id)
    مثل: مبادرة، بلدية، شركة، ... إلخ
    """

    # بيانات الحساب / الجهة
    name_ar: str
    name_en: str
    mobile_number: str
    government_id: int
    account_type_id: int

    # رابط عام للحساب (مثل نموذج انضمام، صفحة ويب، إلخ)
    account_link: str | None = None

    show_details: bool = True
    logo_url: str | None = None

    # بيانات الدخول
    username: str
    password: str = Field(min_length=6)


# ============================================================
# REGISTER ACCOUNT
# ============================================================

@router.post("/register/account", status_code=201)
def register_account(payload: AccountRegisterIn, db: Session = Depends(get_db)):
    """
    إنشاء حساب جديد (أي نوع من أنواع الحسابات في جدول account_types)
    + إنشاء مستخدم مرتبط بهذا الحساب في جدول users.

    المنطق:
      - التأكد من عدم تكرار اسم المستخدم أو رقم الهاتف
      - التحقق من government_id
      - التحقق من account_type_id
      - إنشاء صف في accounts
      - إنشاء صف في users بقيمة user_type=2 و account_id=الحساب الجديد
    """

    return controller_register_account(payload=payload, db=db)


# ============================================================
# LOGIN
# ============================================================

@router.post("/login", response_model=TokenOut)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """
    Login using OAuth2 form:
      - username
      - password

    Returns signed JWT with:
      - sub       (user id)
      - user_type (1=admin, 2=account)
      - type      ("admin" / "account")
      - account_id (if user linked to an account)
    """

    return controller_login(form_data=form_data, db=db)


# ============================================================
# CHANGE PASSWORD (current logged-in user)
# ============================================================

@router.post("/change-password", status_code=204)
def change_password(
    payload: ChangePasswordIn,
    db: Session = Depends(get_db),
    current=Depends(get_current_user_payload),
):
    """
    Change password for the currently logged-in user (by JWT).
    No need to send user_id; it's taken from token.sub.
    """

    return controller_change_password(payload=payload, db=db, current=current)
