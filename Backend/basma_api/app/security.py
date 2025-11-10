# app/security.py
from __future__ import annotations

import os
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from passlib.context import CryptContext

# ---------------- Password hashing ----------------
# Use PBKDF2 by default (no 72-byte limit). Keep bcrypt enabled for verifying old hashes.
pwd_context = CryptContext(
    schemes=["pbkdf2_sha256", "bcrypt"],
    default="pbkdf2_sha256",
    deprecated="auto",
)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# ---------------- JWT settings ----------------
JWT_SECRET = os.getenv("JWT_SECRET", "CHANGE_ME_SUPER_SECRET")
JWT_ALG = os.getenv("JWT_ALG", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))  # 24h


def create_access_token(
    data: Optional[Dict[str, Any]] = None,
    expires_delta: Optional[timedelta] = None,
    **claims: Any,  # allow create_access_token(sub="..."), etc.
) -> str:
    """
    Create a signed JWT.
    - Pass a dict in `data` and/or keyword claims like sub="123".
    - Exp is added automatically (default 24h unless overridden).
    """
    to_encode: Dict[str, Any] = {}
    if data:
        to_encode.update(data)
    if claims:
        to_encode.update(claims)

    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALG)


def decode_token(token: str) -> Dict[str, Any]:
    """
    Decode and validate a JWT. Raises HTTP 401 on failure.
    Returns the JWT payload (dict) on success.
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

# ---------------- FastAPI dependency (optional) ----------------
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def get_current_user_payload(token: str = Depends(oauth2_scheme)) -> Dict[str, Any]:
    """
    Dependency you can use in routes:
      current = Depends(get_current_user_payload)
    Returns the decoded JWT payload.
    """
    return decode_token(token)
