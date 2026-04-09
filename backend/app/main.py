from fastapi import FastAPI
from app.core.database import check_db_connection

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    print("--- Checking Database Connection ---")
    is_alive, message = check_db_connection()
    if is_alive:
        print(f"DB STATUS: {message}")
    else:
        print(f"DB STATUS: {message}")