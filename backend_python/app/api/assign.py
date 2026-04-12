from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db

router = APIRouter()

@router.post("/to-incident")
def assign_responder(payload: dict, db: Session = Depends(get_db)):
    responder_id = payload.get("responder_id")
    incident_id = payload.get("incident_id")

    if not responder_id or not incident_id:
        raise HTTPException(status_code=400, detail="Missing IDs")

    db.execute(text("""
        UPDATE responders 
        SET status = 'busy', current_incident_id = :inc_id 
        WHERE id = :res_id
    """), {"inc_id": incident_id, "res_id": responder_id})

    db.execute(text("""
        UPDATE incidents 
        SET status = 'in-progress' 
        WHERE id = :inc_id
    """), {"inc_id": incident_id})

    db.commit()
    return {"status": "assigned", "responder_id": responder_id, "incident_id": incident_id}

@router.get("/nearby-responders")
def get_nearby_responders(lat: float, lng: float, r_type: str, db: Session = Depends(get_db)):
    query = text("""
        SELECT id, name, last_location_lat, last_location_lng 
        FROM responders 
        WHERE type = :r_type AND status = 'active'
        AND ABS(last_location_lat - :lat) < 0.05
        AND ABS(last_location_lng - :lng) < 0.05
    """)
    responders = db.execute(query, {"lat": lat, "lng": lng, "r_type": r_type}).fetchall()
    
    return [{"id": r.id, "name": r.name, "lat": r.last_location_lat, "lng": r.last_location_lng} for r in responders]

@router.post("/release/{responder_id}")
def release_responder(responder_id: str, db: Session = Depends(get_db)):
    db.execute(text("""
        UPDATE responders 
        SET status = 'active', current_incident_id = NULL 
        WHERE id = :id
    """), {"id": responder_id})
    db.commit()
    return {"status": "released", "responder_id": responder_id}