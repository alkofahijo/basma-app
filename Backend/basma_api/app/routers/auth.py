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

    # 1) Unique username
    existing_user = db.scalar(select(User).where(User.username == payload.username))
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    # 2) Unique mobile
    existing_account = db.scalar(
        select(Account).where(Account.mobile_number == payload.mobile_number),
    )
    if existing_account:
        raise HTTPException(status_code=400, detail="Mobile already exists")

    # 3) Validate government
    gov = db.get(Government, payload.government_id)
    if not gov or gov.is_active != 1:
        raise HTTPException(status_code=400, detail="Invalid government_id")

    # 4) Validate account_type
    acc_type = db.get(AccountType, payload.account_type_id)
    if not acc_type:
        # لو أضفت عمود is_active في AccountType يمكنك التحقق منه هنا
        raise HTTPException(status_code=400, detail="Invalid account_type_id")

    # 5) Create account row
    account = Account(
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        government_id=payload.government_id,
        account_type_id=payload.account_type_id,
        # NOTE: تأكد أن لديك عمود account_link في جدول accounts لو تريد تخزينه
        # أو غيّر الاسم إلى join_form_link حسب تصميمك
        # مثلاً لو لديك join_form_link:
        # join_form_link = payload.account_link,
        logo_url=payload.logo_url,
        show_details=1 if payload.show_details else 0,
        reports_completed_count=0,
        is_active=1,
    )
    db.add(account)
    db.flush()  # generate account.id

    # 6) Create linked user
    # Normal users (linked to accounts) => user_type = 2
    user = User(
        username=payload.username,
        hashed_password=hash_password(payload.password),
        user_type=2,
        account_id=account.id,
    )
    db.add(user)

    db.commit()

    return {
        "account_id": account.id,
        "username": user.username,
    }


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

    user = db.scalar(select(User).where(User.username == form_data.username))
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    # BUILD JWT TOKEN
    token = create_access_token(
        sub=str(user.id),
        user_type=user.user_type,
        account_id=user.account_id,
    )

    return TokenOut(access_token=token)


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

    user_id = current.get("sub")
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    try:
        user_id_int = int(user_id)
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid token subject")

    user = db.get(User, user_id_int)
    if not user or user.is_active != 1:
        raise HTTPException(status_code=401, detail="User not found or inactive")

    if not payload.new_password or len(payload.new_password) < 6:
        raise HTTPException(
            status_code=400,
            detail="New password must be at least 6 characters",
        )

    user.hashed_password = hash_password(payload.new_password)
    db.add(user)
    db.commit()
    return None
