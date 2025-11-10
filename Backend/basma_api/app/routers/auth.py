# app/routers/auth.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import User, Citizen, Initiative
from ..schemas import TokenOut, CitizenCreate, CitizenOut, InitiativeCreate, InitiativeOut
from ..security import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register/citizen", response_model=CitizenOut, status_code=201)
def register_citizen(payload: CitizenCreate, db: Session = Depends(get_db)):
    # Check unique username & mobile
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=400, detail="Username already exists")
    # Create citizen
    citizen = Citizen(
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        government_id=payload.government_id,
    )
    db.add(citizen)
    db.flush()

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


@router.post("/register/initiative", response_model=InitiativeOut, status_code=201)
def register_initiative(payload: InitiativeCreate, db: Session = Depends(get_db)):
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=400, detail="Username already exists")

    initiative = Initiative(
        name_ar=payload.name_ar,
        name_en=payload.name_en,
        mobile_number=payload.mobile_number,
        join_form_link=payload.join_form_link,
        government_id=payload.government_id,
        logo_url=payload.logo_url,
    )
    db.add(initiative)
    db.flush()

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


@router.post("/login", response_model=TokenOut)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Accepts application/x-www-form-urlencoded fields:
      - grant_type=password
      - username
      - password
      - scope (optional)
      - client_id (optional)
      - client_secret (optional)
    """
    user = db.scalar(select(User).where(User.username == form_data.username))
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    token = create_access_token(sub=str(user.id))
    return TokenOut(access_token=token)
