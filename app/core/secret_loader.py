# app/core/secret_loader.py
from abc import ABC, abstractmethod


class SecretLoader(ABC):
    @abstractmethod
    def load_secrets(self) -> dict[str, str]:
        """Return a dictionary of secrets keyed by the config attribute names."""
        pass
