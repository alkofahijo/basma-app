# app/routers/ai_reports.py
from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.orm import Session

from app.db import get_db
from app.controllers import ai_reports_controller as controller

router = APIRouter(prefix="/ai", tags=["AI"])


@router.post("/resolve-location", response_model=controller.ResolveLocationResponse)
async def ai_resolve_location(payload: controller.ResolveLocationRequest, db: Session = Depends(get_db)):
    return await controller.ai_resolve_location(payload, db)


@router.post("/analyze-image", response_model=controller.AnalyzeImageResponse)
async def ai_analyze_image(
    file: UploadFile = File(...),
    gov_id: int = 0,
    dist_id: int = 0,
    area_id: int = 0,
    db: Session = Depends(get_db),
):
    clf = controller.get_classifier_service()
    return await controller.ai_analyze_image(file=file, gov_id=gov_id, dist_id=dist_id, area_id=area_id, db=db, clf=clf)


@router.post("/debug-reverse-geo")
async def debug_reverse_geo(payload: controller.ResolveLocationRequest):
    return await controller.debug_reverse_geo(payload)
