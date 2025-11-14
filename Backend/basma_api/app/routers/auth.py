from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import User, Citizen, Initiative
from ..schemas import (
    TokenOut,
    CitizenCreate,
    CitizenOut,
    InitiativeCreate,
    InitiativeOut,
)
from ..security import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user_payload,
)

router = APIRouter(prefix="/auth", tags=["auth"])


# ------------------------------------------
# REQUEST MODEL: CHANGE PASSWORD
# ------------------------------------------
class ChangePasswordIn(BaseModel):
    new_password: str


# ------------------------------------------
# REGISTER CITIZEN
# ------------------------------------------
@router.post("/register/citizen", response_model=CitizenOut, status_code=201)
def register_citizen(payload: CitizenCreate, db: Session = Depends(get_db)):

    # Unique username
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=400, detail="Username already exists")

    # Unique mobile
    if db.scalar(select(Citizen).where(Citizen.mobile_number == payload.mobile_number)):
        raise HTTPException(status_code=400, detail="Mobile already exists")

    # Create citizen
    citizen = Citizen(
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        government_id=payload.government_id,
    )
    db.add(citizen)
    db.flush()  # must flush so citizen.id is generated

    # Create linked user
    user = User(
        username=payload.username,
        hashed_password=hash_password(payload.password),
        user_type=3,  # citizen
        citizen_id=citizen.id,
    )
    db.add(user)
    db.commit()
    db.refresh(citizen)
    return citizen


# ------------------------------------------
# REGISTER INITIATIVE
# ------------------------------------------
@router.post("/register/initiative", response_model=InitiativeOut, status_code=201)
def register_initiative(payload: InitiativeCreate, db: Session = Depends(get_db)):

    # Unique username
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=400, detail="Username already exists")

    # Unique mobile (لو حابب تتأكد من عدم تكرار رقم الجوال للمبادرات أيضًا)
    if db.scalar(
        select(Initiative).where(Initiative.mobile_number == payload.mobile_number)
    ):
        raise HTTPException(status_code=400, detail="Mobile already exists")

    # Create initiative
    initiative = Initiative(
        name_ar=payload.name_ar,
        name_en=payload.name_en,  # 🔥 مهم جداً
        mobile_number=payload.mobile_number,
        join_form_link=payload.join_form_link,
        government_id=payload.government_id,
        logo_url=payload.logo_url,
    )
    db.add(initiative)
    db.flush()  # حتى يتم توليد initiative.id

    # Create linked user
    user = User(
        username=payload.username,
        hashed_password=hash_password(payload.password),
        user_type=2,  # initiative
        initiative_id=initiative.id,
    )
    db.add(user)
    db.commit()
    db.refresh(initiative)
    return initiative


# ------------------------------------------
# LOGIN
# ------------------------------------------
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
      sub, user_type, type, citizen_id/initiative_id
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
        citizen_id=user.citizen_id,
        initiative_id=user.initiative_id,
    )

    return TokenOut(access_token=token)


# ------------------------------------------
# CHANGE PASSWORD (current logged-in user)
# ------------------------------------------
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
