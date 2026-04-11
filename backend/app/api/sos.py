"""SOS API module.

This module provides a minimal placeholder for handling SOS alerts.
Add your actual integration with your notification or alerting systems here.
"""

from typing import Dict, Optional


def send_sos_alert(user_id: str, location: Optional[Dict[str, float]] = None, message: str = "SOS alert") -> Dict[str, str]:
    """Handle an SOS alert for a user.

    Args:
        user_id: Identifier for the user triggering the SOS alert.
        location: Optional latitude/longitude location data.
        message: Optional custom message text.

    Returns:
        A simple result dictionary for confirmation.
    """
    # TODO: Integrate with the actual alert notification system here.
    payload = {
        "status": "received",
        "user_id": user_id,
        "message": message,
        "location": location if location is not None else {},
    }
    return payload


if __name__ == "__main__":
    test_payload = send_sos_alert(
        user_id="test_user",
        location={"latitude": 0.0, "longitude": 0.0},
        message="Test SOS alert",
    )
    print("SOS payload:", test_payload)
