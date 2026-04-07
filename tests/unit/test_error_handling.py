import json
import uuid
from unittest.mock import MagicMock

from app.routes import _error_response, _get_correlation_id


def test_get_correlation_id_with_header() -> None:
    mock_request = MagicMock()
    mock_request.headers = {"X-Correlation-ID": "my-corr-id"}
    result = _get_correlation_id(mock_request)
    assert result == "my-corr-id"


def test_get_correlation_id_without_header() -> None:
    mock_request = MagicMock()
    mock_request.headers = {}
    result = _get_correlation_id(mock_request)
    # Should be a valid UUID string
    parsed = uuid.UUID(result)
    assert str(parsed) == result


def test_error_response_status_and_body() -> None:
    response = _error_response("test-corr-id")
    assert response.status_code == 500
    body = json.loads(response.body)
    assert body["error"] == "Internal server error"
    assert body["detail"] == "An unexpected error occurred while processing the request."
    assert body["correlation_id"] == "test-corr-id"
    assert response.headers["X-Correlation-ID"] == "test-corr-id"
