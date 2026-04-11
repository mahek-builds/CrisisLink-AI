def get_incident_suggestions(incident_type, unique_count, priority):
    suggestions = {
        "required_units": 1,
        "team_type": "Standard",
        "action_plan": "Dispatch nearest responder",
        "equipment": []
    }

    if incident_type.lower() == "fire":
        suggestions["team_type"] = "Fire Brigade & Rescue"
        suggestions["equipment"] = ["Water Tanker", "Oxygen Masks", "Fire Extinguishers"]
    elif incident_type.lower() == "medical":
        suggestions["team_type"] = "Ambulance / Paramedics"
        suggestions["equipment"] = ["First Aid Kit", "Stretcher", "Defibrillator"]
    elif incident_type.lower() == "police":
        suggestions["team_type"] = "Patrol Unit / Quick Response Team"
        suggestions["equipment"] = ["Restraints", "Communication Gear"]

    if unique_count >= 5 or priority == "CRITICAL":
        suggestions["required_units"] = 3
        suggestions["action_plan"] = "Immediate Multi-Unit Dispatch + Area Cordoning"
    elif unique_count >= 3 or priority == "HIGH":
        suggestions["required_units"] = 2
        suggestions["action_plan"] = "Dual-Unit Dispatch for backup"
    
    if unique_count > 10:
        suggestions["action_plan"] += " + Notify Senior Supervisor and District Command"

    return suggestions