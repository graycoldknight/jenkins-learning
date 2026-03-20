import pytest
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config['TESTING'] = True
    with flask_app.test_client() as client:
        yield client


def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_greet(client):
    response = client.get('/greet/Jenkins')
    assert response.status_code == 200
    assert response.get_json() == {"message": "Hello, Jenkins!"}


def test_add(client):
    response = client.get('/add/3/4')
    assert response.status_code == 200
    assert response.get_json() == {"result": 7}
