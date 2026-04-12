from datetime import datetime

def check_for_fraud(user_phone, current_lat, current_lng, last_reports):
    if not last_reports:
        return False, "Verified"

    last_report = last_reports[0]
    
    time_diff = (datetime.now() - last_report['created_at']).total_seconds() / 60
    dist_diff = abs(current_lat - last_report['lat']) + abs(current_lng - last_report['lng'])
    
    if time_diff < 1 and dist_diff > 0.1:
        return True, "Impossible Speed"

    if len(last_reports) > 5:
        return True, "Spam Pattern"

    return False, "Verified"