import logging
import uuid

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse

from app.models import (
    ErrorResponseModel,
    ExceptionWatchRequestModel,
    HistoryMessageModel,
    RequestModel,
    ResponseModel,
)
from app.services import agent_orchestrator
from app.services.agent_contracts import ResponseMessage

router = APIRouter()


def _get_correlation_id(request: Request) -> str:
    return request.headers.get("X-Correlation-ID", str(uuid.uuid4()))


def _error_response(correlation_id: str) -> JSONResponse:
    body = ErrorResponseModel(
        error="Internal server error",
        detail="An unexpected error occurred while processing the request.",
        correlation_id=correlation_id,
    )
    return JSONResponse(
        status_code=500,
        content=body.model_dump(),
        headers={"X-Correlation-ID": correlation_id},
    )


@router.post("/ask", response_model=ResponseModel)
async def get_answer(request: RequestModel, raw_request: Request) -> ResponseModel:
    correlation_id = _get_correlation_id(raw_request)
    try:
        response_message: ResponseMessage = await agent_orchestrator.get_answer(request)
        logging.info(f"Response: {response_message.answer}")

        return ResponseModel(
            answer=response_message.answer,
            historyMessages=[
                HistoryMessageModel(role=msg.role, message=msg.message) for msg in response_message.historyMessages
            ],
            agentsGroupChat=[
                HistoryMessageModel(role=msg.role, message=msg.message) for msg in response_message.groupChat
            ],
            sources=response_message.sources if response_message.sources else None,
            suggestions=(response_message.suggestions if response_message.suggestions else None),
            prompt_tokens=str(response_message.prompt_tokens),
            completion_tokens=str(response_message.completion_tokens),
        )
    except Exception:
        logging.exception("Unhandled error in /ask [correlation_id=%s]", correlation_id)
        return _error_response(correlation_id)


@router.post("/fix/exceptions", response_model=ResponseModel)
async def fix_exceptions(request: ExceptionWatchRequestModel, raw_request: Request) -> ResponseModel:
    correlation_id = _get_correlation_id(raw_request)
    try:
        response_message: ResponseMessage = await agent_orchestrator.search_for_exceptions_and_report(request)
        logging.info(f"Response: {response_message.answer}")

        return ResponseModel(
            answer=response_message.answer,
            historyMessages=[
                HistoryMessageModel(role=msg.role, message=msg.message) for msg in response_message.historyMessages
            ],
            agentsGroupChat=[
                HistoryMessageModel(role=msg.role, message=msg.message) for msg in response_message.groupChat
            ],
            sources=response_message.sources if response_message.sources else None,
            suggestions=(response_message.suggestions if response_message.suggestions else None),
            prompt_tokens=str(response_message.prompt_tokens),
            completion_tokens=str(response_message.completion_tokens),
        )
    except Exception:
        logging.exception("Unhandled error in /fix/exceptions [correlation_id=%s]", correlation_id)
        return _error_response(correlation_id)
