# app/core/env_secret_loader.py
import logging
import os
from typing import Dict

from .secret_loader import SecretLoader

logger = logging.getLogger(__name__)


class EnvSecretLoader(SecretLoader):
    def load_secrets(self) -> Dict[str, str]:
        """
        Loads secrets from environment variables.
        """
        logger.info("Loading secrets from environment variables...")
        return {
            "GH_TOKEN": os.getenv("GH_TOKEN", ""),
            "API_KEYS": os.getenv("API_KEYS", ""),
            "IMAGES_DEPLOYMENT_NAME": os.getenv("IMAGES_DEPLOYMENT_NAME", ""),
            "IMAGES_API_KEY": os.getenv("IMAGES_API_KEY", ""),
            "IMAGES_BASE_URL": os.getenv("IMAGES_BASE_URL", ""),
            "IMAGES_API_VERSION": os.getenv("IMAGES_API_VERSION", ""),
            "ISSUES_DEPLOYMENT_NAME": os.getenv("ISSUES_DEPLOYMENT_NAME", ""),
            "ISSUES_API_KEY": os.getenv("ISSUES_API_KEY", ""),
            "ISSUES_BASE_URL": os.getenv("ISSUES_BASE_URL", ""),
            "ISSUES_API_VERSION": os.getenv("ISSUES_API_VERSION", ""),
            "WIKIS_DEPLOYMENT_NAME": os.getenv("WIKIS_DEPLOYMENT_NAME", ""),
            "WIKIS_API_KEY": os.getenv("WIKIS_API_KEY", ""),
            "WIKIS_BASE_URL": os.getenv("WIKIS_BASE_URL", ""),
            "WIKIS_API_VERSION": os.getenv("WIKIS_API_VERSION", ""),
            "REVIEWER_DEPLOYMENT_NAME": os.getenv("REVIEWER_DEPLOYMENT_NAME", ""),
            "REVIEWER_API_KEY": os.getenv("REVIEWER_API_KEY", ""),
            "REVIEWER_BASE_URL": os.getenv("REVIEWER_BASE_URL", ""),
            "REVIEWER_API_VERSION": os.getenv("REVIEWER_API_VERSION", ""),
        }
