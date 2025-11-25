import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load .env file
load_dotenv()

# Read variables from .env
MYSQL_HOST = os.getenv("DB_HOST")
MYSQL_PORT = os.getenv("DB_PORT")
MYSQL_USER = os.getenv("DB_USER")
MYSQL_PASSWORD = os.getenv("DB_PASSWORD")
MYSQL_DB = os.getenv("DB_NAME")

# Connection URL (with utf8mb4 for Arabic)
DATABASE_URL = (
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
    "?charset=utf8mb4"
)

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=3600,
    pool_size=10,
    max_overflow=20,
    echo=False,
    future=True,
)

# Session factory
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    future=True,
)

# Dependency to get a DB session per request (for FastAPI)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()