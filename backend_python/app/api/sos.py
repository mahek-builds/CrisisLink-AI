from fastapi import APIRouter

# Ye line hona zaroori hai
router = APIRouter()

@router.post("/create")
def create_sos(data: dict):
    return {"status": "success"}