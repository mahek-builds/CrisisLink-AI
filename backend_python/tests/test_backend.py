"""HTTP tests for all registered API routers (SQLite test schema)."""
import pytest
from starlette.testclient import TestClient

from app.main import app


@pytest.fixture()
def client():
    with TestClient(app) as c:
        yield c


def test_root(client: TestClient):
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "Online"
    assert "project" in body


def test_incidents_active_empty_then_seeded(client: TestClient):
    r = client.get("/api/incidents/active")
    assert r.status_code == 200
    assert r.json() == []

    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (40.0, -74.0, 'med', 'active', 1, 'HIGH')"""
            )
        )
    r2 = client.get("/api/incidents/active")
    assert r2.status_code == 200
    assert len(r2.json()) == 1


def test_incident_detail_and_404(client: TestClient):
    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        rid = conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (41.0, -73.0, 'fire', 'active', 2, 'MEDIUM')
                RETURNING id"""
            )
        ).scalar_one()
        conn.execute(
            text(
                """INSERT INTO reports
                (incident_id, phone_number, report_type, latitude, longitude)
                VALUES (:iid, '5550001', 'fire', 41.0, -73.0)"""
            ),
            {"iid": rid},
        )

    ok = client.get(f"/api/incidents/{rid}")
    assert ok.status_code == 200
    data = ok.json()
    assert "details" in data and "reports" in data
    assert len(data["reports"]) >= 1

    missing = client.get("/api/incidents/999999")
    assert missing.status_code == 404


def test_reports_routes(client: TestClient):
    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        rid = conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (42.0, -72.0, 'police', 'active', 1, 'LOW')
                RETURNING id"""
            )
        ).scalar_one()
        conn.execute(
            text(
                """INSERT INTO reports
                (incident_id, phone_number, report_type)
                VALUES (:iid, '5550002', 'police')"""
            ),
            {"iid": rid},
        )

    by_inc = client.get(f"/api/reports/incident/{rid}")
    assert by_inc.status_code == 200
    assert isinstance(by_inc.json(), list)
    assert len(by_inc.json()) == 1

    empty_inc = client.get("/api/reports/incident/999998")
    assert empty_inc.status_code == 200
    assert empty_inc.json()["data"] == []

    hist = client.get("/api/reports/user/5550002")
    assert hist.status_code == 200
    assert hist.json()["phone"] == "5550002"
    assert len(hist.json()["data"]) >= 1


def test_admin_stats_and_live_and_resolve(client: TestClient):
    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (43.0, -71.0, 'med', 'active', 1, 'CRITICAL')"""
            )
        )
        conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (43.1, -71.1, 'med', 'in-progress', 2, 'HIGH')"""
            )
        )
        iid = conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (43.2, -71.2, 'fire', 'resolved', 1, 'LOW')
                RETURNING id"""
            )
        ).scalar_one()

    stats = client.get("/api/admin/stats")
    assert stats.status_code == 200
    s = stats.json()
    assert "active" in s and "working" in s and "resolved" in s

    live = client.get("/api/admin/live-incidents")
    assert live.status_code == 200
    assert isinstance(live.json(), list)

    res = client.post(f"/api/admin/resolve/{iid}")
    assert res.status_code == 200
    assert res.json()["status"] == "success"


def test_ai_predict_text_and_analyze(client: TestClient):
    r = client.post("/api/ai/predict-text", json={"text": ""})
    assert r.status_code == 200
    assert "error" in r.json()

    r2 = client.post("/api/ai/predict-text", json={"text": "building on fire smoke"})
    assert r2.status_code == 200
    assert "predicted_type" in r2.json()

    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        iid = conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (44.0, -70.0, 'med', 'active', 1, 'MEDIUM')
                RETURNING id"""
            )
        ).scalar_one()

    no_reports = client.get(f"/api/ai/analyze/{iid}")
    assert no_reports.status_code == 400

    with supabase_client.engine.begin() as conn:
        conn.execute(
            text(
                """INSERT INTO reports
                (incident_id, phone_number, report_type, latitude, longitude)
                VALUES (:iid, '5550003', 'med', 44.0, -70.0)"""
            ),
            {"iid": iid},
        )

    ok = client.get(f"/api/ai/analyze/{iid}")
    assert ok.status_code == 200
    assert "analysis" in ok.json()

    missing = client.get("/api/ai/analyze/999997")
    assert missing.status_code == 404


def test_assign_flow(client: TestClient):
    from sqlalchemy import text
    from app.db import supabase_client

    with supabase_client.engine.begin() as conn:
        iid = conn.execute(
            text(
                """INSERT INTO incidents
                (latitude, longitude, type, status, unique_reporters, priority)
                VALUES (45.0, -69.0, 'med', 'active', 1, 'MEDIUM')
                RETURNING id"""
            )
        ).scalar_one()
        rid = conn.execute(
            text(
                """INSERT INTO responders
                (name, last_location_lat, last_location_lng, type, status)
                VALUES ('Unit A', 45.0, -69.0, 'med', 'active')
                RETURNING id"""
            )
        ).scalar_one()

    near = client.get(
        "/api/assign/nearby-responders",
        params={"lat": 45.0, "lng": -69.0, "r_type": "med"},
    )
    assert near.status_code == 200
    assert len(near.json()) >= 1

    bad = client.post("/api/assign/to-incident", json={})
    assert bad.status_code == 400

    assign = client.post(
        "/api/assign/to-incident",
        json={"responder_id": str(rid), "incident_id": str(iid)},
    )
    assert assign.status_code == 200
    assert assign.json()["status"] == "assigned"

    rel = client.post(f"/api/assign/release/{rid}")
    assert rel.status_code == 200
    assert rel.json()["status"] == "released"


def test_sos_create_validation_and_success(client: TestClient):
    bad = client.post("/api/sos/create", json={"latitude": 1})
    assert bad.status_code == 400

    body = {
        "latitude": 46.0,
        "longitude": -68.0,
        "phone_number": "5550100",
        "type": "police",
    }
    r = client.post("/api/sos/create", json=body)
    assert r.status_code == 200
    out = r.json()
    assert out["status"] == "success"
    assert "incident_id" in out

    r2 = client.post("/api/sos/create", json=body)
    assert r2.status_code == 200
