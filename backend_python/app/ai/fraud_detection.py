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
    last_created = _as_datetime(last_report["created_at"])

    time_diff = (datetime.now(timezone.utc) - last_created).total_seconds() / 60
    dist_diff = abs(current_lat - last_report['lat']) + abs(current_lng - last_report['lng'])
    
    if time_diff < 1 and dist_diff > 0.1:
        return True, "Impossible Speed"

    if len(last_reports) > 5:
        return True, "Spam Pattern"

    return False, "Verified"