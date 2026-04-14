from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db
from app.utils.distance import is_within_radius
from app.ai.priority_prediction import predict_priority
from uuid import UUID

router = APIRouter()

def serialize_value(value):
    """Convert database values to JSON-serializable types"""
    if isinstance(value, UUID):
        return str(value)
    return value

@router.post("/create")
def create_sos(data: dict, db: Session = Depends(get_db)):
    try:
        # 1. Extract Incoming Data
        user_lat = data.get("latitude")
        user_lng = data.get("longitude")
        user_phone = data.get("phone_number")
        report_type = data.get("type") # med, fire, police

        if not all([user_lat, user_lng, user_phone, report_type]):
            raise HTTPException(status_code=400, detail="Missing required fields")

        # 2. Clustering Logic: 1km ke radius mein active incident dhoondo
        # SQL query for proximity check (approx 0.009 degree = 1km)
        find_nearby_query = text("""
            SELECT id, latitude, longitude FROM incidents 
            WHERE status = 'active' 
            AND ABS(latitude - :lat) < 0.009 
            AND ABS(longitude - :lng) < 0.009 
            LIMIT 1
        """)
        nearby_incident = db.execute(find_nearby_query, {"lat": user_lat, "lng": user_lng}).fetchone()

        target_incident_id = None

        if nearby_incident:
            # Purana incident mil gaya, uski ID use karo
            target_incident_id = nearby_incident.id
        else:
            # Naya incident create karo
            create_incident_query = text("""
                INSERT INTO incidents (latitude, longitude, type, status, unique_reporters, priority) 
                VALUES (:lat, :lng, :type, 'active', 1, 'MEDIUM') 
                RETURNING id
            """)
            result = db.execute(create_incident_query, {
                "lat": user_lat, 
                "lng": user_lng, 
                "type": report_type
            }).fetchone()
            if result:
                target_incident_id = result.id
            db.commit()

        if not target_incident_id:
            raise HTTPException(status_code=500, detail="Failed to create or find incident")

        # 3. Deduplication: Check if this Phone Number already reported THIS incident
        check_report_query = text("""
            SELECT id FROM reports 
            WHERE incident_id = :inc_id AND phone_number = :phone
        """)
        existing_report = db.execute(check_report_query, {
            "inc_id": target_incident_id, 
            "phone": user_phone
        }).fetchone()

        if not existing_report:
            # Agar naya phone number hai, toh report insert karo
            db.execute(text("""
                INSERT INTO reports (incident_id, phone_number, report_type) 
                VALUES (:inc_id, :phone, :type)
            """), {
                "inc_id": target_incident_id, 
                "phone": user_phone, 
                "type": report_type
            })
            db.commit()

        # 4. Priority Update: Calculate unique reporters and update priority
        count_query = text("SELECT COUNT(DISTINCT phone_number) FROM reports WHERE incident_id = :inc_id")
        unique_count = db.execute(count_query, {"inc_id": target_incident_id}).scalar()

        # AI Logic call karke priority calculate karo
        new_priority = predict_priority(unique_count)

        # 5. Final Update to Incidents Table
        update_incident_query = text("""
            UPDATE incidents 
            SET priority = :priority, unique_reporters = :count 
            WHERE id = :inc_id
        """)
        db.execute(update_incident_query, {
            "priority": new_priority, 
            "count": unique_count, 
            "inc_id": target_incident_id
        })
        db.commit()

        return {
            "status": "success",
            "incident_id": serialize_value(target_incident_id),
            "unique_reporters": unique_count,
            "priority": new_priority
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error creating SOS report: {str(e)}")