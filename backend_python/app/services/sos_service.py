from sqlalchemy.orm import Session
from sqlalchemy import text
from app.ai.fraud_detection import check_for_fraud
from app.services.report_service import add_new_report
from fastapi import HTTPException

def process_sos_request(db: Session, lat: float, lng: float, phone: str, r_type: str):
    user_history = db.execute(text("""
        SELECT latitude, longitude, created_at FROM reports 
        WHERE phone_number = :phone AND created_at > NOW() - INTERVAL '24 hours'
        ORDER BY created_at DESC
    """), {"phone": phone}).fetchall()

    is_fraud, reason = check_for_fraud(phone, lat, lng, user_history)
    if is_fraud:
        return {"status": "fraud_detected", "reason": reason}

    find_nearby_query = text("""
        SELECT id FROM incidents 
        WHERE status = 'active' 
        AND ABS(latitude - :lat) < 0.009 
        AND ABS(longitude - :lng) < 0.009 
        LIMIT 1
    """)
    nearby_incident = db.execute(find_nearby_query, {"lat": lat, "lng": lng}).fetchone()

    if nearby_incident:
        target_id = nearby_incident.id
    else:
        create_query = text("""
            INSERT INTO incidents (latitude, longitude, type, status, unique_reporters, priority) 
            VALUES (:lat, :lng, :type, 'active', 0, 'LOW') 
            RETURNING id
        """)
        target_id = db.execute(create_query, {"lat": lat, "lng": lng, "type": r_type}).fetchone().id
        db.commit()

    success, result = add_new_report(db, target_id, phone, r_type)
    
    return {
        "status": "success" if success else "ignored",
        "incident_id": str(target_id),
        "data": result
    }