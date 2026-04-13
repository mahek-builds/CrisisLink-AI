from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from app.db.supabase_client import get_db
from sqlalchemy import text
router=APIRouter()
@router.get("/incident/{incident_id}")
def get_reports_by_incidents(incident_id:str,db:Session=Depends(get_db)):
    query=text("""SELECT id, phone_number, report_type, created_at FROM reports WHERE incident_id=:inc_id ORDER BY created_at DESC""")
    result=db.execute(query,{"inc_id":incident_id}).fetchall()
    if not result:
        return {"msg": "No reports found for this incident", "data": []}
    return[dict(r._mapping )for r in result]
@router.get("/user/{phone_number}")
def get_history(phone_number:str,db:Session=Depends(get_db)):
    query=text("""select r.report_type,r.created_at,i.status,i.priority from reports r JOIN incidents i ON r.incident_id=i.id WHERE r.phone_number=:phone ORDER BY r.created_at DESC""")
    result=db.execute(query,{"phone":phone_number}).fetchall()
    return {
        "phone":phone_number,
        "data": [dict(r._mapping) for r in result]
    }


