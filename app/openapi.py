from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def get_openapi_schema(app: FastAPI) -> dict:
    return get_openapi(
        title="QnA API",
        version="1.0",
        description="API for handling Q&A",
        routes=app.routes,
    )
