from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException

def assign_responder_to_incident(db: Session, responder_id: str, incident_id: str):
    # 1. Check if responder is available
    responder = db.execute(
        text("SELECT status FROM responders WHERE id = :id"), 
        {"id": responder_id}
    ).fetchone()

    if not responder:
        raise HTTPException(status_code=404, detail="Responder not found")
    
    if responder.status != 'active':
        raise HTTPException(status_code=400, detail="Responder is already busy or offline")

    try:
        # 2. Update Responder status
        db.execute(text("""
            UPDATE responders 
            SET status = 'busy', current_incident_id = :inc_id 
            WHERE id = :res_id
        """), {"inc_id": incident_id, "res_id": responder_id})

        # 3. Update Incident status
        db.execute(text("""
            UPDATE incidents 
            SET status = 'in-progress' 
            WHERE id = :inc_id
        """), {"inc_id": incident_id})

        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Assignment failed: {str(e)}")

def release_responder_service(db: Session, responder_id: str):
    try:
        db.execute(text("""
            UPDATE responders 
            SET status = 'active', current_incident_id = NULL 
            WHERE id = :id
        """), {"id": responder_id})
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        return False