from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from uuid import UUID

class IncidentBase(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    type: str = Field(..., pattern="^(fire|medical|police|other)$")
    status: str = Field(default="active", pattern="^(active|in-progress|resolved)$")

class IncidentCreate(IncidentBase):
    pass

class IncidentUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(active|in-progress|resolved)$")
    priority: Optional[str] = Field(None, pattern="^(LOW|MEDIUM|HIGH|CRITICAL)$")
    unique_reporters: Optional[int] = Field(None, ge=0)

class IncidentResponse(IncidentBase):
    id: UUID
    priority: str
    unique_reporters: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class IncidentListResponse(BaseModel):
    incidents: List[IncidentResponse]