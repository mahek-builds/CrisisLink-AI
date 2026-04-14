from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.supabase_client import get_db
from app.schemas.incident_schema import IncidentResponse
from datetime import datetime
from uuid import UUID

router = APIRouter()

def serialize_result(data):
    """Convert database row to JSON-serializable dict"""
    if data is None:
        return None
    result = dict(data._mapping)
    for key, value in result.items():
        if isinstance(value, UUID):
            result[key] = str(value)
        elif isinstance(value, datetime):
            result[key] = value.isoformat()
    return result

@router.get("/active")
def get_active_incidents(db: Session = Depends(get_db)):
    try:
        query = text("""
            SELECT id, latitude, longitude, type, priority, unique_reporters, created_at 
            FROM incidents 
            WHERE status = 'active' 
            ORDER BY created_at DESC
        """)
        result = db.execute(query).fetchall()
        return [serialize_result(r) for r in result]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/{incident_id}")
def get_incident_details(incident_id: str, db: Session = Depends(get_db)):
    try:
        incident_id = str(incident_id).strip()
        inc_query = text("SELECT * FROM incidents WHERE id = CAST(:id AS uuid)")
        incident = db.execute(inc_query, {"id": incident_id}).fetchone()
        if not incident:
            raise HTTPException(status_code=404, detail="Incident not found")
        
        rep_query = text("SELECT phone_number, report_type, created_at FROM reports WHERE incident_id = CAST(:id AS uuid)")
        reports = db.execute(rep_query, {"id": incident_id}).fetchall()
        
        return {
            "details": serialize_result(incident),
            "reports": [serialize_result(r) for r in reports]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
