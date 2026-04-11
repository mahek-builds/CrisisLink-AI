def predict_priority(unique_count):    
    if unique_count >= 5:
        return "CRITICAL"
    elif unique_count >= 3:
        return "HIGH"
    elif unique_count >= 2:
        return "MEDIUM"
    else:
        return "LOW"