# app/core/keyvault_secret_loader.py
import logging

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

from .secret_loader import SecretLoader

logger = logging.getLogger(__name__)


class KeyVaultSecretLoader(SecretLoader):
    def __init__(self, vault_name: str):
        """
        vault_name: the name of your Key Vault (e.g. 'my-keyvault').
        """
        self.vault_name = vault_name

    def load_secrets(self) -> dict[str, str]:
        logger.info("Loading secrets from Key Vault...")
        secrets = {}

        if not self.vault_name:
            raise OSError("KEYVAULT_NAME is not set or empty.")

        keyvault_uri = f"https://{self.vault_name}.vault.azure.net/"
        credential = DefaultAzureCredential()

        client = SecretClient(vault_url=keyvault_uri, credential=credential)

        secret_names = [
            "gh-token",
            "api-keys",
            "images-deployment-name",
            "images-api-key",
            "images-base-url",
            "images-api-version",
            "issues-deployment-name",
            "issues-api-key",
            "issues-base-url",
            "issues-api-version",
            "wikis-deployment-name",
            "wikis-api-key",
            "wikis-base-url",
            "wikis-api-version",
            "reviewer-deployment-name",
            "reviewer-api-key",
            "reviewer-base-url",
            "reviewer-api-version",
        ]

        for secret_name in secret_names:
            # Convert "GH-TOKEN" -> "GH_TOKEN" for the dictionary key
            attribute_name = secret_name.replace("-", "_").upper()
            try:
                fetched_secret = client.get_secret(secret_name)
                secrets[attribute_name] = fetched_secret.value
                logger.debug(f"Fetched secret {secret_name} -> {attribute_name}")
            except Exception as e:
                logger.warning(f"Failed to fetch {secret_name} from Key Vault: {e}")

        return secrets
