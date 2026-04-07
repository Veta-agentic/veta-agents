from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.services.agent_contracts import ResponseMessage

TEST_API_KEY = "test-api-key-1"

ASK_PAYLOAD = {
    "question": "What is AI?",
    "githubWikis": ["https://wiki.example.com"],
    "githubWikiBaseImageUrl": "https://images.example.com/",
    "githubRepo": "owner/repo",
}

FIX_EXCEPTIONS_PAYLOAD = {
    "azureLogAnalyticsWorkspaceId": "workspace-123",
    "githubRepo": "owner/repo",
}


def _make_response_message(answer: str = "Test answer") -> ResponseMessage:
    rm = ResponseMessage()
    rm.answer = answer
    rm.add_user_message("What is AI?")
    rm.add_assistant_message(answer)
    rm.sources = ["https://example.com"]
    rm.suggestions = ["Follow up question"]
    rm.prompt_tokens = 10
    rm.completion_tokens = 20
    return rm


@pytest.mark.asyncio
async def test_ask_success() -> None:
    mock_response = _make_response_message()
    with (
        patch("app.auth.api_keys", [TEST_API_KEY]),
        patch(
            "app.services.agent_orchestrator.get_answer",
            new=AsyncMock(return_value=mock_response),
        ),
    ):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post("/ask", json=ASK_PAYLOAD, headers={"X-API-Key": TEST_API_KEY})
            assert response.status_code == 200
            data = response.json()
            assert data["answer"] == "Test answer"
            assert len(data["historyMessages"]) == 2
            assert data["sources"] == ["https://example.com"]
            assert data["suggestions"] == ["Follow up question"]
            assert data["prompt_tokens"] == "10"
            assert data["completion_tokens"] == "20"


@pytest.mark.asyncio
async def test_ask_error_returns_500() -> None:
    with (
        patch("app.auth.api_keys", [TEST_API_KEY]),
        patch(
            "app.services.agent_orchestrator.get_answer",
            new=AsyncMock(side_effect=Exception("boom")),
        ),
    ):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post("/ask", json=ASK_PAYLOAD, headers={"X-API-Key": TEST_API_KEY})
            assert response.status_code == 500
            data = response.json()
            assert data["error"] == "Internal server error"
            assert "detail" in data
            assert "correlation_id" in data


@pytest.mark.asyncio
async def test_fix_exceptions_success() -> None:
    mock_response = _make_response_message("Exceptions found")
    with (
        patch("app.auth.api_keys", [TEST_API_KEY]),
        patch(
            "app.services.agent_orchestrator.search_for_exceptions_and_report",
            new=AsyncMock(return_value=mock_response),
        ),
    ):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post(
                "/fix/exceptions",
                json=FIX_EXCEPTIONS_PAYLOAD,
                headers={"X-API-Key": TEST_API_KEY},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["answer"] == "Exceptions found"


@pytest.mark.asyncio
async def test_fix_exceptions_error_returns_500() -> None:
    with (
        patch("app.auth.api_keys", [TEST_API_KEY]),
        patch(
            "app.services.agent_orchestrator.search_for_exceptions_and_report",
            new=AsyncMock(side_effect=Exception("boom")),
        ),
    ):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post(
                "/fix/exceptions",
                json=FIX_EXCEPTIONS_PAYLOAD,
                headers={"X-API-Key": TEST_API_KEY},
            )
            assert response.status_code == 500
            data = response.json()
            assert data["error"] == "Internal server error"


@pytest.mark.asyncio
async def test_missing_api_key_returns_401() -> None:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.post("/ask", json=ASK_PAYLOAD)
        assert response.status_code == 401


@pytest.mark.asyncio
async def test_invalid_api_key_returns_401() -> None:
    with patch("app.auth.api_keys", [TEST_API_KEY]):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            response = await ac.post(
                "/ask",
                json=ASK_PAYLOAD,
                headers={"X-API-Key": "wrong-key"},
            )
            assert response.status_code == 401
