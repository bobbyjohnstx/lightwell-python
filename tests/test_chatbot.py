import json
import pytest
from chatbot.app import app, RESPONSES


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index_returns_html(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Customer Support" in response.data


def test_chat_valid_message(client):
    response = client.post(
        "/chat",
        data=json.dumps({"message": "Hello"}),
        content_type="application/json",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert "response" in data
    assert data["response"] in RESPONSES


def test_chat_empty_message(client):
    response = client.post(
        "/chat",
        data=json.dumps({"message": ""}),
        content_type="application/json",
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["response"] == "I didn't catch that. Could you rephrase?"


def test_chat_whitespace_only(client):
    response = client.post(
        "/chat",
        data=json.dumps({"message": "   "}),
        content_type="application/json",
    )
    data = response.get_json()
    assert data["response"] == "I didn't catch that. Could you rephrase?"


def test_chat_missing_message_key(client):
    response = client.post(
        "/chat",
        data=json.dumps({"other": "value"}),
        content_type="application/json",
    )
    data = response.get_json()
    assert data["response"] == "I didn't catch that. Could you rephrase?"


def test_chat_no_json_body(client):
    response = client.post("/chat", content_type="text/plain", data="hello")
    assert response.status_code == 200
    data = response.get_json()
    assert data["response"] == "I didn't catch that. Could you rephrase?"


def test_chat_malformed_json(client):
    response = client.post(
        "/chat", content_type="application/json", data="not json"
    )
    assert response.status_code == 200
    data = response.get_json()
    assert data["response"] == "I didn't catch that. Could you rephrase?"


def test_chat_returns_varied_responses(client):
    responses = set()
    for _ in range(50):
        r = client.post(
            "/chat",
            data=json.dumps({"message": "test"}),
            content_type="application/json",
        )
        responses.add(r.get_json()["response"])
    assert len(responses) > 1, "Expected varied responses from canned list"
