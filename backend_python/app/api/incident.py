from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.supabase_client import get_db
router=APIRouter()
@router.get("/active")
def get_active_incidents(db:Session=Depends(get_db)):
    query=text("""
        SELECT id, latitude, longitude, type, priority, unique_reporters, created_at 
        FROM incidents 
        WHERE status = 'active' 
        ORDER BY created_at DESC
    """)
    result=db.execute(query).fetchall()
    return [dict(r.mapping)for r in result]

@router.get("/{incident_id}")
def get_incident_details(incident_id:str,db:Session=Depends(get_db)):
    inc_query=text("SELECT * FROM incidents WHERE id = :id")
    incident=db.execute(inc_query,{"id":incident_id}).fetchone()
    if not incident:
        raise HTTPException(status_code=404,detail="Incident not found")
    rep_query = text("SELECT phone_number, report_type, created_at FROM reports WHERE incident_id = :id")
    reports = db.execute(rep_query, {"id": incident_id}).fetchall()
    
    return {
        "details": dict(incident._mapping),
        "reports": [dict(r._mapping) for r in reports]
    }
