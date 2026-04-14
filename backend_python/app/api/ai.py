from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db
from app.ai.type_prediction import predict_type
from app.ai.suggestion_engine import get_incident_suggestions
from app.ai.priority_prediction import predict_priority
from app.ai.fraud_detection import check_for_fraud
from datetime import datetime

router = APIRouter()

def serialize_value(value):
    """Convert database values to JSON-serializable types"""
    if isinstance(value, datetime):
        return value.isoformat()
    return value

@router.get("/analyze/{incident_id}")
def analyze_incident(incident_id: str, db: Session = Depends(get_db)):
    try:
        incident_id = str(incident_id).strip()
        incident = db.execute(
            text("SELECT * FROM incidents WHERE id = CAST(:id AS uuid)"), 
            {"id": incident_id}
        ).fetchone()

        if not incident:
            raise HTTPException(status_code=404, detail="Incident not found")

        reports = db.execute(
            text("SELECT * FROM reports WHERE incident_id = CAST(:id AS uuid) ORDER BY created_at DESC"),
            {"id": incident_id}
        ).fetchall()

        report_list = [r.phone_number for r in reports]
        unique_count = len(set(report_list))

        if not reports:
            raise HTTPException(
                status_code=400,
                detail="No reports found for this incident",
            )

        # AI Analysis Execution
        priority = predict_priority(unique_count)
        suggestions = get_incident_suggestions(incident.type, unique_count, priority)
        
        user_history = [{"lat": r.latitude, "lng": r.longitude, "created_at": serialize_value(r.created_at)} for r in reports]
        is_fraud, fraud_reason = check_for_fraud(reports[0].phone_number, incident.latitude, incident.longitude, user_history)

        return {
            "incident_id": incident_id,
            "analysis": {
                "predicted_priority": priority,
                "unique_reporters": unique_count,
                "fraud_check": {
                    "is_suspicious": is_fraud,
                    "reason": fraud_reason
                },
                "recommendations": suggestions
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(e)}")

@router.post("/predict-text")
def predict_from_text(payload: dict):
    try:
        text_input = payload.get("text", "")
        if not text_input:
            return {"error": "No text provided"}
        
        predicted_type = predict_type(text_input)
        return {"input_text": text_input, "predicted_type": predicted_type}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")