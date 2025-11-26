# app/core/config.py
import logging
from typing import Dict

logger = logging.getLogger(__name__)


class Config:
    def __init__(self, secrets: Dict[str, str], is_development: bool):
        """
        Takes a dictionary of secrets (e.g., from Env or KeyVault)
        and makes them available as attributes.
        """
        self.ISDEVELOPMENT = is_development
        self.GH_TOKEN = secrets.get("GH_TOKEN", "")
        self.APIKEYS = secrets.get("API_KEYS", "")
        self.IMAGES_DEPLOYMENT_NAME = secrets.get("IMAGES_DEPLOYMENT_NAME", "")
        self.IMAGES_API_KEY = secrets.get("IMAGES_API_KEY", "")
        self.IMAGES_BASE_URL = secrets.get("IMAGES_BASE_URL", "")
        self.IMAGES_API_VERSION = secrets.get("IMAGES_API_VERSION", "")
        self.ISSUES_DEPLOYMENT_NAME = secrets.get("ISSUES_DEPLOYMENT_NAME", "")
        self.ISSUES_API_KEY = secrets.get("ISSUES_API_KEY", "")
        self.ISSUES_BASE_URL = secrets.get("ISSUES_BASE_URL", "")
        self.ISSUES_API_VERSION = secrets.get("ISSUES_API_VERSION", "")
        self.WIKIS_DEPLOYMENT_NAME = secrets.get("WIKIS_DEPLOYMENT_NAME", "")
        self.WIKIS_API_KEY = secrets.get("WIKIS_API_KEY", "")
        self.WIKIS_BASE_URL = secrets.get("WIKIS_BASE_URL", "")
        self.WIKIS_API_VERSION = secrets.get("WIKIS_API_VERSION", "")
        self.REVIEWER_DEPLOYMENT_NAME = secrets.get("REVIEWER_DEPLOYMENT_NAME", "")
        self.REVIEWER_API_KEY = secrets.get("REVIEWER_API_KEY", "")
        self.REVIEWER_BASE_URL = secrets.get("REVIEWER_BASE_URL", "")
        self.REVIEWER_API_VERSION = secrets.get("REVIEWER_API_VERSION", "")

        # Optionally validate to ensure required secrets are present
        self._validate_secrets()

    def _validate_secrets(self) -> None:
        """
        Raises EnvironmentError if any required secrets are missing.
        """

        required_fields = [
            "GH_TOKEN",
            "IMAGES_DEPLOYMENT_NAME",
            "IMAGES_API_KEY",
            "IMAGES_BASE_URL",
            "IMAGES_API_VERSION",
            "ISSUES_DEPLOYMENT_NAME",
            "ISSUES_API_KEY",
            "ISSUES_BASE_URL",
            "ISSUES_API_VERSION",
            "WIKIS_DEPLOYMENT_NAME",
            "WIKIS_API_KEY",
            "WIKIS_BASE_URL",
            "WIKIS_API_VERSION",
            "REVIEWER_DEPLOYMENT_NAME",
            "REVIEWER_API_KEY",
            "REVIEWER_BASE_URL",
            "REVIEWER_API_VERSION",
        ]

        missing = [f for f in required_fields if not getattr(self, f)]
        if missing:
            logger.error(f"Missing required secrets: {missing}")
            raise OSError(f"Missing required secrets: {missing}")
