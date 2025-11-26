# app/core/secret_loader.py
from abc import ABC, abstractmethod
from typing import Dict


class SecretLoader(ABC):
    @abstractmethod
    def load_secrets(self) -> Dict[str, str]:
        """Return a dictionary of secrets keyed by the config attribute names."""
        pass
