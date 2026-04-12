from sqlalchemy.orm import Session 
from sqlalchemy import text
def get_reports_summary(db:Session,incident_id):
    query = text("""
        SELECT report_type FROM reports 
        WHERE incident_id = :inc_id
    """)
    result = db.execute(query, {"inc_id": incident_id})
    return [r.report_type for r in result]
def check_user_reputation(db: Session, phone_number: str):
    query = text("""
        SELECT COUNT(*) FROM reports r
        JOIN incidents i ON r.incident_id = i.id
        WHERE r.phone_number = :phone AND i.status = 'false_alarm'
    """)
    false_alarms = db.execute(query, {"phone": phone_number}).scalar()
    
    return {"is_reliable": false_alarms < 3, "false_alarms": false_alarms}