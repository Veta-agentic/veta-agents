from fastapi import Depends, FastAPI

from app.auth import check_apikey
from app.core.insightsmiddleware import InsightsMiddleware
from app.openapi import get_openapi_schema
from app.routes import router

app = FastAPI()

app.add_middleware(InsightsMiddleware)
app.include_router(router, dependencies=[Depends(check_apikey)])


@app.get("/openapi.json")
def openapi_schema() -> dict:
    return get_openapi_schema(app)
