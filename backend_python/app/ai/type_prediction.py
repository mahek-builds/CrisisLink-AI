from collections import Counter

def predict_type(report_list): 
    if not report_list:
        return "unknown", 0
        
    type_counts = Counter(report_list)
    final_type, count = type_counts.most_common(1)[0]
    confidence = (count / len(report_list)) * 100

    if len(type_counts) >= 2:
        top_two = type_counts.most_common(2)
        if top_two[0][1] == top_two[1][1]:
            priorities = ["fire", "medical", "police"]
            for p in priorities:
                if p in [top_two[0][0], top_two[1][0]]:
                    final_type = p
                    break
                    
    return final_type, confidence