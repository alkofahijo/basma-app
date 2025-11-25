from __future__ import annotations

import os
import uuid
from pathlib import Path
from typing import Tuple

from fastapi import HTTPException, status
from fastapi import File, UploadFile
from fastapi.responses import JSONResponse

# Resolve directories relative to this module
HERE = Path(__file__).resolve().parent
APP_DIR = HERE.parent
STATIC_DIR = APP_DIR / "static"
UPLOADS_DIR = STATIC_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
ALLOWED_CT = {
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
}


def _choose_ext(content_type: str | None, filename: str | None) -> str:
    ext = ""
    if filename:
        _, ext = os.path.splitext(filename)
        ext = (ext or "").lower()

    if ext in ALLOWED_EXTS:
        return ext

    if content_type in ALLOWED_CT:
        if content_type == "image/jpeg":
            return ".jpg"
        if content_type == "image/png":
            return ".png"
        if content_type == "image/gif":
            return ".gif"
        if content_type == "image/webp":
            return ".webp"

    return ".jpg"


def _validate_file(file: UploadFile) -> Tuple[str, str | None]:
    ct = (file.content_type or "").lower() or None
    ext = _choose_ext(ct, file.filename)

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


async def upload_image_endpoint(file: UploadFile = File(...)) -> JSONResponse:
    ext, _ = _validate_file(file)
    dest = _save_path(ext)
    with dest.open("wb") as f:
        while True:
            chunk = await file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    return JSONResponse({"url": _public_url(dest)})


async def upload_image_legacy_endpoint(file: UploadFile = File(...)) -> JSONResponse:
    return await upload_image_endpoint(file=file)
