import pytest
from pydantic import ValidationError

from app.models import (
    ErrorResponseModel,
    ExceptionWatchRequestModel,
    HistoryMessageModel,
    RequestModel,
    ResponseModel,
)


def test_request_model_with_required_fields() -> None:
    model = RequestModel(
        question="test?",
        githubWikis=["https://wiki.example.com"],
        githubWikiBaseImageUrl="https://images.example.com/",
        githubRepo="owner/repo",
    )
    assert model.question == "test?"
    assert model.user is None
    assert model.sessionId is None
    assert model.historyMessages is None


def test_request_model_missing_required_field() -> None:
    with pytest.raises(ValidationError):
        RequestModel(question="test?")


def test_response_model_construction() -> None:
    model = ResponseModel(
        answer="answer",
        historyMessages=[HistoryMessageModel(role="user", message="hi")],
        agentsGroupChat=[],
        sources=["https://example.com"],
        suggestions=["follow up"],
        prompt_tokens="10",
        completion_tokens="20",
    )
    assert model.answer == "answer"
    assert len(model.historyMessages) == 1
    assert model.historyMessages[0].role == "user"
    assert model.sources == ["https://example.com"]
    assert model.prompt_tokens == "10"


def test_error_response_model() -> None:
    model = ErrorResponseModel(
        error="Internal server error",
        detail="Something went wrong",
        correlation_id="abc-123",
    )
    assert model.error == "Internal server error"
    assert model.detail == "Something went wrong"
    assert model.correlation_id == "abc-123"


def test_error_response_model_optional_correlation_id() -> None:
    model = ErrorResponseModel(
        error="err",
        detail="detail",
    )
    assert model.correlation_id is None


def test_exception_watch_request_model_camel_alias() -> None:
    model = ExceptionWatchRequestModel.model_validate(
        {
            "azureLogAnalyticsWorkspaceId": "workspace-123",
            "githubRepo": "owner/repo",
        }
    )
    assert model.azure_log_analytics_workspace_id == "workspace-123"
    assert model.github_repo == "owner/repo"
    assert model.days == 1
