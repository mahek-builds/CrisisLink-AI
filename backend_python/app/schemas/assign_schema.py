from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID

class AssignmentRequest(BaseModel):
    responder_id: UUID = Field(..., description="ID of the responder/unit")
    incident_id: UUID = Field(..., description="ID of the incident")

class ResponderNearbyRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    responder_type: str = Field(..., pattern="^(fire|medical|police)$")

class AssignmentResponse(BaseModel):
    status: str
    responder_id: UUID
    incident_id: UUID
    message: Optional[str] = None

    class Config:
        from_attributes = True