import logging

from fastapi import APIRouter

from app.models import ExceptionWatchRequestModel, HistoryMessageModel, RequestModel, ResponseModel
from app.services import agent_orchestrator
from app.services.agent_contracts import ResponseMessage

router = APIRouter()


@router.post("/ask", response_model=ResponseModel)
async def get_answer(request: RequestModel) -> ResponseModel:
    try:
        response_message: ResponseMessage = await agent_orchestrator.get_answer(request)
        logging.info(f"Response: {response_message.answer}")

        # Construcción del modelo de respuesta
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
    except Exception as e:
        logging.error(f"Error: {e}")
        return ResponseModel(
            answer=f"Error processing the request exception {e}",
            historyMessages=[],
            agentsGroupChat=[],
            sources=[],
            suggestions=[],
        )


@router.post("/fix/exceptions", response_model=ResponseModel)
async def fix_exceptions(request: ExceptionWatchRequestModel) -> ResponseModel:
    try:
        response_message: ResponseMessage = await agent_orchestrator.search_for_exceptions_and_report(request)
        logging.info(f"Response: {response_message.answer}")

        # Construcción del modelo de respuesta
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
    except Exception as e:
        logging.error(f"Error: {e}")
        return ResponseModel(
            answer=f"Error processing the request exception {e}",
            historyMessages=[],
            agentsGroupChat=[],
            sources=[],
            suggestions=[],
        )
