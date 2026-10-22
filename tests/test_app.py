from app.app import app


def test_home():
    client = app.test_client()
    r = client.get("/")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_health():
    client = app.test_client()
    assert client.get("/health").get_json()["status"] == "healthy"
