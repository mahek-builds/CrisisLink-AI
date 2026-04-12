from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db

router = APIRouter()

@router.get("/stats")
def get_admin_stats(db: Session = Depends(get_db)):
    query = text("""
        SELECT 
            COUNT(*) FILTER (WHERE status = 'active') as active_cases,
            COUNT(*) FILTER (WHERE status = 'in-progress') as working_cases,
            COUNT(*) FILTER (WHERE status = 'resolved') as resolved_today
        FROM incidents
    """)
    stats = db.execute(query).fetchone()
    return {
        "active": stats.active_cases,
        "working": stats.working_cases,
        "resolved": stats.resolved_today
    }

@router.get("/live-incidents")
def get_live_incidents(db: Session = Depends(get_db)):
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
            "id": str(inc.id),
            "latitude": inc.latitude,
            "longitude": inc.longitude,
            "type": inc.type,
            "priority": inc.priority,
            "status": inc.status,
            "reporters": inc.unique_reporters,
            "created_at": inc.created_at
        })
    return result

@router.post("/resolve/{incident_id}")
def resolve_incident(incident_id: str, db: Session = Depends(get_db)):
    query = text("UPDATE incidents SET status = 'resolved' WHERE id = :id")
    db.execute(query, {"id": incident_id})
    db.commit()
    return {"status": "success", "message": f"Incident {incident_id} marked as resolved"}