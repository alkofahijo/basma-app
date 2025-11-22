from __future__ import annotations
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .routers import admin_auth, admin_users, admin_accounts, admin_reports ,  report_lookups

from .db import engine
from .models import Base
from .routers.locations import router as locations_router
from .routers.auth import router as auth_router
from .routers.reports import router as reports_router

from .routers.uploads import uploads_router, files_router

from app.routers import accounts, auth
from app.routers import ai_reports


Base.metadata.create_all(bind=engine)

app = FastAPI(title="Basma API", version="2.0.0")

origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files (images)
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
os.makedirs(os.path.join(STATIC_DIR, "uploads"), exist_ok=True)
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

# Routes
app.include_router(locations_router)
app.include_router(auth_router)
app.include_router(reports_router)
# ⬇️ include both, so /uploads and /files/upload are available
app.include_router(uploads_router)
app.include_router(files_router)
app.include_router(auth.router)
app.include_router(accounts.router)
app.include_router(ai_reports.router)
# Admins 
app.include_router(admin_auth.router)
app.include_router(admin_users.router)
app.include_router(admin_accounts.router)
app.include_router(admin_reports.router)
app.include_router(report_lookups.router)

@app.get("/")
def root():
    return {"status": "ok"}
