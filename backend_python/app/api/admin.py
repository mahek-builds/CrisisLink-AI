from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db
from datetime import datetime
from uuid import UUID

router = APIRouter()

def serialize_value(value):
    """Convert database values to JSON-serializable types"""
    if isinstance(value, UUID):
        return str(value)
    elif isinstance(value, datetime):
        return value.isoformat()
    return value

@router.get("/stats")
def get_admin_stats(db: Session = Depends(get_db)):
    try:
        query = text("""
            SELECT 
                COUNT(*) FILTER (WHERE status = 'active') as active_cases,
                COUNT(*) FILTER (WHERE status = 'in-progress') as working_cases,
                COUNT(*) FILTER (WHERE status = 'resolved') as resolved_today
            FROM incidents
        """)
        stats = db.execute(query).fetchone()
        return {
            "active": stats.active_cases or 0,
            "working": stats.working_cases or 0,
            "resolved": stats.resolved_today or 0
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/live-incidents")
def get_live_incidents(db: Session = Depends(get_db)):
    try:
        query = text("""
            SELECT * FROM incidents 
            WHERE status != 'resolved' 
            ORDER BY 
                CASE WHEN priority = 'CRITICAL' THEN 1
                     WHEN priority = 'HIGH' THEN 2
                     WHEN priority = 'MEDIUM' THEN 3
                     ELSE 4 END,
                unique_reporters DESC
        """)
        incidents = db.execute(query).fetchall()
        
        result = []
        for inc in incidents:
            result.append({
                "id": serialize_value(inc.id),
                "latitude": inc.latitude,
                "longitude": inc.longitude,
                "type": inc.type,
                "priority": inc.priority,
                "status": inc.status,
                "reporters": inc.unique_reporters,
                "created_at": serialize_value(inc.created_at)
            })
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.post("/resolve/{incident_id}")
def resolve_incident(incident_id: str, db: Session = Depends(get_db)):
    try:
        incident_id = str(incident_id).strip()
        query = text("UPDATE incidents SET status = 'resolved' WHERE id = CAST(:id AS uuid)")
        db.execute(query, {"id": incident_id})
        db.commit()
        return {"status": "success", "message": f"Incident {incident_id} marked as resolved"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")