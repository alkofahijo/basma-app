# app/db.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# --- MySQL 8.0.43 connection settings ---
MYSQL_HOST = "127.0.0.1"
MYSQL_PORT = 3306
MYSQL_USER = "root"
MYSQL_PASSWORD = "admin"
MYSQL_DB = "basmadb"

# Use PyMySQL driver; keep utf8mb4 for full Arabic support
DATABASE_URL = (
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
    "?charset=utf8mb4"
)

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,     # validates connections, avoids stale pool issues
    pool_recycle=3600,      # recycle connections every hour
    pool_size=10,           # base pool size
    max_overflow=20,        # extra connections beyond pool_size
    echo=False,             # set True for SQL debug logging
    future=True,            # SQLAlchemy 2.0 style
)

# Session factory
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    future=True,
)

# Dependency to get a DB session per request (FastAPI)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
