from unittest.mock import MagicMock, patch

import pytest

from app.core.config import Config
from app.core.config_factory import clear_config_cache, get_config


def _full_secrets() -> dict[str, str]:
    return {
        "GH_TOKEN": "tok",
        "API_KEYS": "key1,key2",
        "IMAGES_DEPLOYMENT_NAME": "img-dep",
        "IMAGES_API_KEY": "img-key",
        "IMAGES_BASE_URL": "https://img.test",
        "IMAGES_API_VERSION": "2024-01-01",
        "ISSUES_DEPLOYMENT_NAME": "iss-dep",
        "ISSUES_API_KEY": "iss-key",
        "ISSUES_BASE_URL": "https://iss.test",
        "ISSUES_API_VERSION": "2024-01-01",
        "WIKIS_DEPLOYMENT_NAME": "wik-dep",
        "WIKIS_API_KEY": "wik-key",
        "WIKIS_BASE_URL": "https://wik.test",
        "WIKIS_API_VERSION": "2024-01-01",
        "REVIEWER_DEPLOYMENT_NAME": "rev-dep",
        "REVIEWER_API_KEY": "rev-key",
        "REVIEWER_BASE_URL": "https://rev.test",
        "REVIEWER_API_VERSION": "2024-01-01",
    }


def test_config_with_all_secrets() -> None:
    cfg = Config(_full_secrets(), is_development=True)
    assert cfg.GH_TOKEN == "tok"
    assert cfg.APIKEYS == "key1,key2"
    assert cfg.ISDEVELOPMENT is True


def test_config_missing_required_secret() -> None:
    secrets = _full_secrets()
    secrets["GH_TOKEN"] = ""
    with pytest.raises(OSError, match="Missing required secrets"):
        Config(secrets, is_development=False)


def test_get_config_caching() -> None:
    clear_config_cache()
    with patch("app.core.config_factory._create_config") as mock_create:
        mock_config = MagicMock()
        mock_create.return_value = mock_config
        c1 = get_config()
        c2 = get_config()
        assert c1 is c2
        mock_create.assert_called_once()
    clear_config_cache()


def test_clear_config_cache_resets() -> None:
    clear_config_cache()
    with patch("app.core.config_factory._create_config") as mock_create:
        mock_create.return_value = MagicMock()
        get_config()
        clear_config_cache()
        get_config()
        assert mock_create.call_count == 2
    clear_config_cache()
