from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

from app.core.config_factory import get_config

api_key_header = APIKeyHeader(name="X-API-Key")

config = get_config()
api_keys = config.APIKEYS.split(",")


def check_apikey(api_key_header: str = Security(api_key_header)) -> str:
    if api_key_header in api_keys:
        return api_key_header
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing or invalid API key")
