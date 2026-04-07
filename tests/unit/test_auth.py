from unittest.mock import patch

import pytest
from fastapi import HTTPException

from app.auth import check_apikey


def test_valid_api_key() -> None:
    with patch("app.auth.api_keys", ["valid-key-1", "valid-key-2"]):
        result = check_apikey("valid-key-1")
        assert result == "valid-key-1"


def test_invalid_api_key_raises_401() -> None:
    with patch("app.auth.api_keys", ["valid-key-1"]):
        with pytest.raises(HTTPException) as exc_info:
            check_apikey("wrong-key")
        assert exc_info.value.status_code == 401
        assert "Missing or invalid API key" in exc_info.value.detail
