from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api import sos, admin, incident, report, assign, ai
from app.db.supabase_client import engine, Base
from app.config.settings import settings

# Database tables auto-creation
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    description="Emergency Response System with AI-driven Priority Logic"
)

# CORS Setup: React/Next.js frontend se connection ke liye zaroori hai
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom Global Error Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"message": "Internal Server Error", "details": str(exc)},
    )

# Registering Routers
app.include_router(sos.router, prefix="/api/sos", tags=["SOS Reporting"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin Dashboard"])
app.include_router(ai.router, prefix="/api/ai", tags=["AI Analysis"])
app.include_router(assign.router, prefix="/api/assign", tags=["Responder Assignment"])
app.include_router(incident.router, prefix="/api/incidents", tags=["Incident Management"])
app.include_router(report.router, prefix="/api/reports", tags=["Detailed Reports"])

@app.get("/")
async def root():
    return {
        "project": settings.PROJECT_NAME,
        "version": settings.PROJECT_VERSION,
        "status": "Online",
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)