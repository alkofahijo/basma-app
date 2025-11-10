from __future__ import annotations

import os
import uuid
from pathlib import Path
from typing import Tuple

from fastapi import APIRouter, File, UploadFile, HTTPException, status
from fastapi.responses import JSONResponse

# Resolve project root and static uploads dir
HERE = Path(__file__).resolve().parent
APP_DIR = HERE.parent
STATIC_DIR = APP_DIR / "static"
UPLOADS_DIR = STATIC_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

# Allowed extensions & content types
ALLOWED_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
ALLOWED_CT = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
}


def _choose_ext(content_type: str | None, filename: str | None) -> str:
    # Try extension from filename
    ext = ""
    if filename:
        _, ext = os.path.splitext(filename)
        ext = (ext or "").lower()

    # If valid ext already, keep it
    if ext in ALLOWED_EXTS:
        return ext

    # Try from content-type
    if content_type in ALLOWED_CT:
        if content_type == "image/jpeg":
            return ".jpg"
        if content_type == "image/png":
            return ".png"
        if content_type == "image/gif":
            return ".gif"
        if content_type == "image/webp":
            return ".webp"

    # Last resort: default to jpg
    return ".jpg"


def _validate_file(file: UploadFile) -> Tuple[str, str | None]:
    # If content-type isn’t provided by client, don’t fail.
    ct = (file.content_type or "").lower() or None
    ext = _choose_ext(ct, file.filename)

    # Finally, ensure ext is one we allow
    if ext not in ALLOWED_EXTS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported file extension",
        )
    return ext, ct


def _save_path(filename_ext: str) -> Path:
    unique = uuid.uuid4().hex
    return UPLOADS_DIR / f"{unique}{filename_ext}"


def _public_url(saved_path: Path) -> str:
    rel = saved_path.relative_to(STATIC_DIR)
    return f"/static/{rel.as_posix()}"


uploads_router = APIRouter(prefix="/uploads", tags=["uploads"])


def _save_path(filename_ext: str) -> Path:
    # unique filename
    unique = uuid.uuid4().hex
    return UPLOADS_DIR / f"{unique}{filename_ext}"


def _public_url(saved_path: Path) -> str:
    # static is mounted at /static in main.py
    # Convert filesystem path under static/ to URL under /static/
    rel = saved_path.relative_to(STATIC_DIR)
    return f"/static/{rel.as_posix()}"


# -------- Preferred router: /uploads --------
uploads_router = APIRouter(prefix="/uploads", tags=["uploads"])


@uploads_router.post("", summary="Upload an image file", response_class=JSONResponse)
async def upload_image(file: UploadFile = File(...)):
    ext, _ = _validate_file(file)
    dest = _save_path(ext)
    with dest.open("wb") as f:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    return {"url": _public_url(dest)}


files_router = APIRouter(prefix="/files", tags=["uploads (legacy)"])

# -------- Legacy compatibility: /files/upload --------
files_router = APIRouter(prefix="/files", tags=["uploads (legacy)"])


@files_router.post(
    "/upload", summary="Legacy upload endpoint", response_class=JSONResponse
)
async def upload_image_legacy(file: UploadFile = File(...)):
    ext, _ = _validate_file(file)
    dest = _save_path(ext)
    with dest.open("wb") as f:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    return {"url": _public_url(dest)}
