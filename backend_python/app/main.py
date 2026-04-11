from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import sos, admin, incident, report, assign
from app.db.supabase_client import engine, Base

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CrisisLink-AI Backend",
    description="Emergency Response System with AI Priority Logic",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sos.router, prefix="/sos", tags=["SOS"])
app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(incident.router, prefix="/incidents", tags=["Incidents"])
app.include_router(report.router, prefix="/reports", tags=["Reports"])
app.include_router(assign.router, prefix="/assign", tags=["Assignment"])

@app.get("/")
def health_check():
    return {
        "status": "Running",
        "project": "CrisisLink-AI",
        "database": "Connected"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)