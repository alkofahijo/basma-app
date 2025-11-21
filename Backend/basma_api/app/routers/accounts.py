# app/routers/accounts.py
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select, or_
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
    stmt = select(AccountType).order_by(AccountType.id.asc())
    rows = db.execute(stmt).scalars().all()
    return rows


# ============================================================
# REQUEST MODELS
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


# ============================================================
# LIST ACCOUNTS
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

    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),   # ✅ نوع الجهة
            joinedload(Account.government),    # ✅ المحافظة
        )
    )

    if account_type_id is not None:
        stmt = stmt.where(Account.account_type_id == account_type_id)

    if government_id is not None:
        stmt = stmt.where(Account.government_id == government_id)

    if is_active is not None:
        stmt = stmt.where(Account.is_active == is_active)

    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            or_(
                Account.name_ar.like(like),
                Account.name_en.like(like),
                Account.mobile_number.like(like),
            )
        )

    stmt = stmt.order_by(Account.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).scalars().all()

    return rows


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

    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account_id)
    )
    account = db.execute(stmt).scalars().first()

    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    return account


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

    # validate references
    if not db.get(Government, payload.government_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid government_id",
        )

    if not db.get(AccountType, payload.account_type_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid account_type_id",
        )

    # unique mobile
    if db.scalar(
        select(Account).where(Account.mobile_number == payload.mobile_number)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        )

    account = Account(
        account_type_id=payload.account_type_id,
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        government_id=payload.government_id,
        logo_url=payload.logo_url,
        join_form_link=payload.join_form_link,
    )
    db.add(account)

    try:
        # flush للحصول على account.id بدون إغلاق الترانزاكشن
        db.flush()
    except IntegrityError as e:
        db.rollback()
        # احتمال تعارض فريد على رقم الموبايل
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        ) from e

    # optional linked user
    if payload.username and payload.password:
        # unique username
        if db.scalar(select(User).where(User.username == payload.username)):
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists",
            )

        user = User(
            username=payload.username,
            hashed_password=hash_password(payload.password),
            user_type=2,  # مستخدم حساب
            account_id=account.id,
        )
        db.add(user)
        try:
            db.flush()
        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already exists",
            ) from e

    db.commit()

    # نعيد القراءة مع العلاقات لو حابب تطلعها أيضاً في الـ response
    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account.id)
    )
    account_with_rels = db.execute(stmt).scalars().first()

    return account_with_rels or account


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
    account = db.get(Account, account_id)
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    data = payload.model_dump(exclude_unset=True)

    # validate account_type_id
    if "account_type_id" in data and data["account_type_id"] is not None:
        if not db.get(AccountType, data["account_type_id"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid account_type_id",
            )
        account.account_type_id = data["account_type_id"]

    # validate government_id
    if "government_id" in data and data["government_id"] is not None:
        if not db.get(Government, data["government_id"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid government_id",
            )
        account.government_id = data["government_id"]

    # simple fields on Account
    for field in [
        "name_ar",
        "name_en",
        "mobile_number",
        "logo_url",
        "is_active",
        "show_details",
        "reports_completed_count",
        "join_form_link",
    ]:
        if field in data:
            setattr(account, field, data[field])

    # handle linked user (username/password)
    if "username" in data or "password" in data:
        user = db.scalar(select(User).where(User.account_id == account.id))

        if user:
            # update existing linked user
            if data.get("username"):
                # check if another user uses this username
                if db.scalar(
                    select(User).where(
                        User.username == data["username"],
                        User.id != user.id,
                    )
                ):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    )
                user.username = data["username"]

            if data.get("password"):
                user.hashed_password = hash_password(data["password"])

            db.add(user)
            try:
                db.flush()
            except IntegrityError as e:
                db.rollback()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already exists",
                ) from e

        else:
            # create new linked user only if both username and password are provided
            if data.get("username") and data.get("password"):
                if db.scalar(
                    select(User).where(User.username == data["username"])
                ):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    )

                new_user = User(
                    username=data["username"],
                    hashed_password=hash_password(data["password"]),
                    user_type=2,
                    account_id=account.id,
                )
                db.add(new_user)
                try:
                    db.flush()
                except IntegrityError as e:
                    db.rollback()
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Username already exists",
                    ) from e
            elif data.get("username") or data.get("password"):
                # واحد فقط من الحقلين → نرجّع خطأ واضح
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Both username and password are required to create a linked user",
                )

    try:
        db.commit()
    except IntegrityError as e:
        db.rollback()
        # غالباً تعارض في رقم الموبايل أو حقل فريد
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already exists",
        ) from e

    # نرجّع الحساب مع العلاقات
    stmt = (
        select(Account)
        .options(
            joinedload(Account.account_type),
            joinedload(Account.government),
        )
        .where(Account.id == account.id)
    )
    updated_account = db.execute(stmt).scalars().first()

    return updated_account or account


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
    account = db.get(Account, account_id)
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found",
        )

    if hard:
        # detach linked users
        users = db.execute(
            select(User).where(User.account_id == account.id)
        ).scalars().all()
        for u in users:
            u.account_id = None
            db.add(u)

        # detach adopted reports
        reports = db.execute(
            select(Report).where(Report.adopted_by_account_id == account.id)
        ).scalars().all()
        for r in reports:
            r.adopted_by_account_id = None
            db.add(r)

        db.delete(account)

    else:
        # soft delete
        account.is_active = 0
        db.add(account)

        # optionally deactivate linked users
        users = db.execute(
            select(User).where(User.account_id == account.id)
        ).scalars().all()
        for u in users:
            u.is_active = 0
            db.add(u)

    db.commit()
    return None
