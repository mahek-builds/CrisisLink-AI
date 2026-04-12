from datetime import datetime
import uuid

def generate_unique_id():
    return str(uuid.uuid4())

def format_timestamp(dt: datetime):
    if not dt:
        return None
    return dt.strftime("%Y-%m-%d %H:%M:%S")

def get_priority_color(priority: str):
    colors = {
        "CRITICAL": "#FF0000", # Red
        "HIGH": "#FFA500",     # Orange
        "MEDIUM": "#FFFF00",   # Yellow
        "LOW": "#00FF00"       # Green
    }
    return colors.get(priority.upper(), "#808080")

def sanitize_phone_number(phone: str):
    # Remove any spaces, dashes or brackets
    return "".join(filter(str.isdigit, phone))

def calculate_priority_score(unique_reporters: int, report_type: str):
    # Basic logic: Har reporter ke 10 points, Fire/Medical ke bonus 20 points
    score = unique_reporters * 10
    if report_type in ["fire", "medical"]:
        score += 20
    return score