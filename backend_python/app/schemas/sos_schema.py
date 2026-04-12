from pydantic import BaseModel, Field, validator
import re

class SOSCreate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone_number: str = Field(..., min_length=10, max_length=15)
    type: str = Field(..., pattern="^(fire|medical|police|other)$")

    @validator('phone_number')
    def validate_phone(cls, v):
        # Basic regex to allow numbers and optional '+'
        if not re.match(r'^\+?[1-9]\d{1,14}$', v):
            raise ValueError('Invalid phone number format')
        return v

class SOSResponse(BaseModel):
    status: str
    incident_id: str
    unique_reporters: int
    priority: str

    class Config:
        from_attributes = True