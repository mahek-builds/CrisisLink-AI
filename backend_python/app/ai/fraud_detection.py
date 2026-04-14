from datetime import datetime, timezone


def _utc(value: datetime) -> datetime:
    """Make value timezone-aware in UTC for safe comparison with datetime.now(timezone.utc)."""
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _as_datetime(value):
    if isinstance(value, datetime):
        return _utc(value)
    if isinstance(value, str):
        s = value.replace("Z", "+00:00")
        try:
            dt = datetime.fromisoformat(s)
        except ValueError:
            dt = datetime.fromisoformat(s.replace(" ", "T", 1))
        return _utc(dt)
    raise TypeError(f"Unsupported datetime value: {type(value)!r}")


def check_for_fraud(user_phone, current_lat, current_lng, last_reports):
    if not last_reports:
        return False, "Verified"

    last_report = last_reports[0]
    
    # Validate required fields
    if not last_report.get("created_at"):
        return False, "Verified"
    
    last_created = _as_datetime(last_report["created_at"])

    time_diff = (datetime.now(timezone.utc) - last_created).total_seconds() / 60
    
    # Handle missing latitude/longitude
    last_lat = last_report.get('lat')
    last_lng = last_report.get('lng')
    
    if last_lat is None or last_lng is None or current_lat is None or current_lng is None:
        # If coordinates are missing, can't calculate distance, assume verified
        dist_diff = 0
    else:
        dist_diff = abs(current_lat - last_lat) + abs(current_lng - last_lng)
    
    if time_diff < 1 and dist_diff > 0.1:
        return True, "Impossible Speed"

    if len(last_reports) > 5:
        return True, "Spam Pattern"

    return False, "Verified"