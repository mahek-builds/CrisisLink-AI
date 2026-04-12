import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    PROJECT_NAME: str = "CrisisLink-AI"
    PROJECT_VERSION: str = "1.0.0"

    DATABASE_URL: str = os.getenv("DATABASE_URL")
    
    # Clustering radius (approx 1km in degrees)
    CLUSTERING_RADIUS: float = 0.009
    
    # API Security (Optional)
    API_KEY_NAME: str = "access_token"
    
    class Config:
        case_sensitive = True

settings = Settings()