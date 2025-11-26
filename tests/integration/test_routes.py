# import pytest
# from httpx import AsyncClient
# from unittest.mock import AsyncMock, patch
# from app.routes import get_answer
# from app.models import RequestModel, ResponseModel, HistoryMessageModel
# from app.services.agent_contracts import ResponseMessage
# from fastapi import FastAPI

# app = FastAPI()
# app.include_router(get_answer.router)

# @pytest.mark.asyncio
# async def test_get_answer_success():
#     mock_request = RequestModel(question="What is AI?")
#     mock_response_message = ResponseMessage(
#         answer="AI stands for Artificial Intelligence.",
#         historyMessages=[
#             HistoryMessageModel(role="user", message="What is AI?"),
#             HistoryMessageModel(role="assistant", message="AI stands for Artificial Intelligence."),
#         ],
#         groupChat=[],
#         sources=["https://example.com"],
#         suggestions=["What is machine learning?"],
#         prompt_tokens=10,
#         completion_tokens=20,
#     )

#     with patch("app.services.agent_orchestrator.get_answer", new=AsyncMock(return_value=mock_response_message)):
#         async with AsyncClient(app=app, base_url="http://test") as ac:
#             response = await ac.post("/ask", json=mock_request.dict())
#             assert response.status_code == 200
#             response_data = response.json()
#             assert response_data["answer"] == mock_response_message.answer
#             assert len(response_data["historyMessages"]) == len(mock_response_message.historyMessages)
#             assert response_data["sources"] == mock_response_message.sources
#             assert response_data["suggestions"] == mock_response_message.suggestions
#             assert response_data["prompt_tokens"] == str(mock_response_message.prompt_tokens)
#             assert response_data["completion_tokens"] == str(mock_response_message.completion_tokens)

# @pytest.mark.asyncio
# async def test_get_answer_exception():
#     mock_request = RequestModel(question="What is AI?")
#     with patch("app.services.agent_orchestrator.get_answer", new=AsyncMock(side_effect=Exception("Test exception"))):
#         async with AsyncClient(app=app, base_url="http://test") as ac:
#             response = await ac.post("/ask", json=mock_request.dict())
#             assert response.status_code == 200
#             response_data = response.json()
#             assert "Error processing the request exception" in response_data["answer"]
#             assert response_data["historyMessages"] == []
#             assert response_data["agentsGroupChat"] == []
#             assert response_data["sources"] == []
#             assert response_data["suggestions"] == []
