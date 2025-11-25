# app/routers/accounts.py
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select, or_, func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

from ..db import get_db
from ..models import Account, AccountType, Government, User, Report
from ..schemas import (
    AccountCreate,
    AccountOut,
    AccountTypeOut,  # ✅ سكيما أنواع الحسابات
)
from ..security import hash_password
from ..controllers.accounts_controller import (
    list_account_types as controller_list_account_types,
    list_accounts as controller_list_accounts,
    list_accounts_paged as controller_list_accounts_paged,
    get_account as controller_get_account,
    create_account as controller_create_account,
    update_account as controller_update_account,
    delete_account as controller_delete_account,
)

router = APIRouter(prefix="/accounts", tags=["accounts"])


# ============================================================
# ACCOUNT TYPES LOOKUP
# ============================================================


@router.get("/types", response_model=List[AccountTypeOut])
def list_account_types(db: Session = Depends(get_db)):
    """
    إرجاع قائمة أنواع الحسابات (Account Types) لاستخدامها في الواجهات.
    لا يحتاج إلى أي باراميترات، لذلك لن يحدث 422 من جهة الـ request.
    """
    return controller_list_account_types(db=db)


# ============================================================
# REQUEST / RESPONSE MODELS
# ============================================================


class AccountUpdate(BaseModel):
    """
    الحقول المسموح بتعديلها على الحساب + بيانات المستخدم المرتبط (اختياري).
    جميع الحقول اختيارية (partial update).
    """
    account_type_id: Optional[int] = None
    name_ar: Optional[str] = None
    name_en: Optional[str] = None
    mobile_number: Optional[str] = None
    government_id: Optional[int] = None
    logo_url: Optional[str] = None
    is_active: Optional[int] = None
    show_details: Optional[int] = None
    reports_completed_count: Optional[int] = None
    join_form_link: Optional[str] = None

    # optional linked user changes
    username: Optional[str] = None
    password: Optional[str] = None


class AccountPaginatedOut(BaseModel):
    """
    استجابة مقسّمة لصفحات (pagination) لقائمة الحسابات.
    """
    total: int
    page: int
    page_size: int
    items: List[AccountOut]


# ============================================================
# LIST ACCOUNTS (OLD, SIMPLE LIST)
# ============================================================


@router.get("", response_model=List[AccountOut])
def list_accounts(
    db: Session = Depends(get_db),
    account_type_id: Optional[int] = Query(None),
    government_id: Optional[int] = Query(None),
    is_active: Optional[int] = Query(None, description="1 or 0"),
    q: Optional[str] = Query(None, description="search name_ar/name_en/mobile"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    """
    إرجاع قائمة الحسابات مع دعم للفلاتر:
      - نوع الحساب (account_type_id)
      - المحافظة (government_id)
      - حالة التفعيل (is_active)
      - نص بحثي على الاسم أو رقم الجوال (q)

    ✅ تم تفعيل تحميل العلاقات:
      - account_type
      - government
    حتى تصل إلى الـ properties:
      - account_type_name_ar / ...etc
      - government_name_ar
    """

    return controller_list_accounts(
        db=db,
        account_type_id=account_type_id,
        government_id=government_id,
        is_active=is_active,
        q=q,
        limit=limit,
        offset=offset,
    )


# ============================================================
# LIST ACCOUNTS WITH PAGINATION (NEW)
# ============================================================


@router.get("/paged", response_model=AccountPaginatedOut)
def list_accounts_paged(
    db: Session = Depends(get_db),
    account_type_id: Optional[int] = Query(None),
    government_id: Optional[int] = Query(None),
    is_active: Optional[int] = Query(None, description="1 or 0"),
    q: Optional[str] = Query(None, description="search name_ar/name_en/mobile"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=200),
):
    """
    إرجاع قائمة الحسابات مع:
      - فلاتر حسب نوع الحساب / المحافظة / حالة التفعيل / بحث نصّي
      - تقسيم على صفحات (page, page_size)
      - إرجاع total لعدد السجلات المطابقة

    مناسب لقوائم "قائمة المتطوعين" في الواجهات مع أزرار التالي / السابق.
    """

    # بناء استعلام أساسي مع العلاقات
    base_stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
    )

    # تطبيق الفلاتر
    if account_type_id is not None:
        base_stmt = base_stmt.where(Account.account_type_id == account_type_id)

    if government_id is not None:
        base_stmt = base_stmt.where(Account.government_id == government_id)

    if is_active is not None:
        base_stmt = base_stmt.where(Account.is_active == is_active)

    if q:
        like = f"%{q}%"
        base_stmt = base_stmt.where(
            or_(
                Account.name_ar.like(like),
                Account.name_en.like(like),
                Account.mobile_number.like(like),
            )
        )

    return controller_list_accounts_paged(
        db=db,
        account_type_id=account_type_id,
        government_id=government_id,
        is_active=is_active,
        q=q,
        page=page,
        page_size=page_size,
    )


# ============================================================
# GET ACCOUNT BY ID
# ============================================================


@router.get("/{account_id}", response_model=AccountOut)
def get_account(account_id: int, db: Session = Depends(get_db)):
    """
    جلب حساب واحد عن طريق المعرف مع تحميل:
      - account_type
      - government
    ليستفيد منها الـ properties مثل account_type_name_ar و government_name_ar.
    """

    return controller_get_account(account_id=account_id, db=db)


# ============================================================
# CREATE ACCOUNT
# ============================================================


@router.post("", response_model=AccountOut, status_code=status.HTTP_201_CREATED)
def create_account(payload: AccountCreate, db: Session = Depends(get_db)):
    """
    إنشاء حساب جديد (Account) مع إمكانية إنشاء مستخدم مرتبط (User) اختيارياً.
    - يتحقق من صحة government_id و account_type_id
    - يتحقق من عدم تكرار رقم الموبايل
    - في حال وجود username/password ينشئ User مرتبط بالحساب (user_type=2)
    """

    return controller_create_account(payload=payload, db=db)


# ============================================================
# UPDATE ACCOUNT
# ============================================================


@router.patch("/{account_id}", response_model=AccountOut)
def update_account(
    account_id: int,
    payload: AccountUpdate,
    db: Session = Depends(get_db),
):
    """
    تحديث بيانات حساب موجود:
      - يمكن تعديل نوع الحساب / الاسم / رقم الجوال / المحافظة / الشعار / التفعيل...
      - يمكن أيضاً تعديل بيانات المستخدم المرتبط (username/password)
      - إذا لم يكن هناك مستخدم مرتبط وتم إرسال username+password → إنشاء مستخدم جديد
    """
    return controller_update_account(account_id=account_id, payload=payload, db=db)


# ============================================================
# DELETE ACCOUNT (soft/hard)
# ============================================================


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: int,
    db: Session = Depends(get_db),
    hard: bool = Query(False, description="Set true to hard-delete (dangerous)"),
):
    """
    حذف الحساب:
      - soft delete (افتراضي): تعيين is_active=0 + إلغاء تفعيل المستخدمين المرتبطين
      - hard delete: إزالة الحساب نهائياً بعد فك الارتباط بالمستخدمين والتقارير المتبنّاة
    """
    return controller_delete_account(account_id=account_id, db=db, hard=hard)
