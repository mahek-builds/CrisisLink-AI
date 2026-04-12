from collections import Counter
def predict_final_type(report_list):
    if not report_list:
        return "unknown"
    type_counts=Counter(report_list)
    # gives in the form of{"fire":3}
    final_type, count = type_counts.most_common(1)[0] # y hmesha list return krta h list k andar tuple hota h
    confidence = (count / len(report_list)) * 100


    #tie -breaker-loic
    if len(type_counts)>2:
        top_two=type_counts.most_common(2)
        if top_two[0][1]==top_two[1][1]:
            priorities=["fire","medical","police"]
            for p in priorities:
                if p in [top_two[0][0],top_two[1][0]]:
                    final_type=p
                    break
    return final_type, confidence

