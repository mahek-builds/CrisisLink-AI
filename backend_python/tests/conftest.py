"""Test DB: set DATABASE_URL before any application imports."""
import os
from pathlib import Path

from sqlalchemy import text

_ROOT = Path(__file__).resolve().parent.parent
_DB_PATH = _ROOT / "pytest_backend_test.sqlite3"

if _DB_PATH.exists():
    try:
        _DB_PATH.unlink()
    except OSError:
        pass

os.environ["DATABASE_URL"] = f"sqlite:///{_DB_PATH.as_posix()}"

from app.db import supabase_client  # noqa: E402


def _create_schema() -> None:
    ddl = [
        "DROP TABLE IF EXISTS reports",
        "DROP TABLE IF EXISTS responders",
        "DROP TABLE IF EXISTS incidents",
        """CREATE TABLE incidents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            type TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            unique_reporters INTEGER DEFAULT 0,
            priority TEXT DEFAULT 'MEDIUM',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )""",
        """CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            incident_id INTEGER NOT NULL,
            phone_number TEXT NOT NULL,
            report_type TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            latitude REAL,
            longitude REAL
        )""",
        """CREATE TABLE responders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            last_location_lat REAL,
            last_location_lng REAL,
            type TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            current_incident_id INTEGER
        )""",
    ]
    with supabase_client.engine.begin() as conn:
        for stmt in ddl:
            conn.execute(text(stmt))


_create_schema()

import pytest


@pytest.fixture(autouse=True)
def _sqlite_clean_tables():
    """Each test starts with empty tables (shared engine)."""
    with supabase_client.engine.begin() as conn:
        conn.execute(text("DELETE FROM reports"))
        conn.execute(text("DELETE FROM responders"))
        conn.execute(text("DELETE FROM incidents"))
    yield
