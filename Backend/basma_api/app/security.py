from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.context import CryptContext


# =====================================================
# 🔐 PASSWORD HASHING (PBKDF2 + bcrypt fallback)
# =====================================================
pwd_context = CryptContext(
    schemes=["pbkdf2_sha256", "bcrypt"],
    default="pbkdf2_sha256",
    deprecated="auto",
)


def hash_password(password: str) -> str:
    """Hash password using PBKDF2_SHA256."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify hashed password."""
    return pwd_context.verify(plain_password, hashed_password)


# =====================================================
# 🔏 JWT SETTINGS
# =====================================================
JWT_SECRET = os.getenv("JWT_SECRET", "CHANGE_ME_SUPER_SECRET")
JWT_ALG = os.getenv("JWT_ALG", "HS256")

# default: 7 days
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))


def _user_type_str(user_type: int) -> str:
    """
    Convert internal numeric user_type:
      1 = admin
      2 = initiative
      3 = citizen
    into consistent string for front-end:
      "admin", "initiative", "citizen"
    """
    if user_type == 1:
        return "admin"
    if user_type == 2:
        return "initiative"
    if user_type == 3:
        return "citizen"
    return "unknown"


# =====================================================
# 🔐 CREATE JWT TOKEN
# =====================================================
def create_access_token(
    *,
    sub: str,  # user.id
    user_type: int,  # 1, 2, or 3
    citizen_id: Optional[int] = None,
    initiative_id: Optional[int] = None,
    expires_delta: Optional[timedelta] = None,
    **extra_claims: Any,
) -> str:
    """
    Create signed JWT with:
      - sub (user id)
      - user_type: 1/2/3
      - type: "admin" / "citizen" / "initiative"
      - citizen_id or initiative_id
      - exp, iat timestamps
    """

    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))

    type_str = _user_type_str(user_type)

    payload: Dict[str, Any] = {
        "sub": sub,
        "user_type": user_type,
        "type": type_str,  # for Flutter: AuthService expects 'type'
        "iat": int(now.timestamp()),
        "exp": expire,
    }

    if citizen_id is not None:
        payload["citizen_id"] = citizen_id

    if initiative_id is not None:
        payload["initiative_id"] = initiative_id

    if extra_claims:
        payload.update(extra_claims)

    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALG)
    return token


# =====================================================
# 🔓 DECODE TOKEN
# =====================================================
def decode_token(token: str) -> Dict[str, Any]:
    """
    Validate & decode JWT.
    Returns payload dict.
    Raises 401 if invalid.
    """
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALG])
        return payload

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


# =====================================================
# 🌐 FASTAPI DEPENDENCY
# =====================================================
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user_payload(token: str = Depends(oauth2_scheme)) -> Dict[str, Any]:
    """
    Used in protected routes:
        current = Depends(get_current_user_payload)
    Returns decoded JWT payload.
    Ensures 'sub' exists in payload.
    """
    payload = decode_token(token)

    if "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return payload
