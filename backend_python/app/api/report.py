from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.supabase_client import get_db
from sqlalchemy import text
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

@router.get("/incident/{incident_id}")
def get_reports_by_incidents(incident_id: str, db: Session = Depends(get_db)):
    try:
        incident_id = str(incident_id).strip()
        query = text("""SELECT id, phone_number, report_type, created_at FROM reports WHERE incident_id=CAST(:inc_id AS uuid) ORDER BY created_at DESC""")
        result = db.execute(query, {"inc_id": incident_id}).fetchall()
        if not result:
            return {"msg": "No reports found for this incident", "data": []}
        return [serialize_result(r) for r in result]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/user/{phone_number}")
def get_history(phone_number: str, db: Session = Depends(get_db)):
    try:
        query = text("""select r.report_type,r.created_at,i.status,i.priority from reports r JOIN incidents i ON r.incident_id=i.id WHERE r.phone_number=:phone ORDER BY r.created_at DESC""")
        result = db.execute(query, {"phone": phone_number}).fetchall()
        return {
            "phone": phone_number,
            "data": [serialize_result(r) for r in result]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


