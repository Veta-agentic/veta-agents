import pytest

from app.services.agent_contracts import ResponseMessage


def test_add_user_message() -> None:
    rm = ResponseMessage()
    rm.add_user_message("Hello")
    assert len(rm.historyMessages) == 1
    assert rm.historyMessages[0].role == "user"
    assert rm.historyMessages[0].message == "Hello"


def test_add_assistant_message() -> None:
    rm = ResponseMessage()
    rm.add_assistant_message("Hi there")
    assert len(rm.historyMessages) == 1
    assert rm.historyMessages[0].role == "assistant"
    assert rm.historyMessages[0].message == "Hi there"


def test_add_group_agent_message() -> None:
    rm = ResponseMessage()
    rm.add_group_agent_message("WikiAgent", "Found it")
    assert len(rm.groupChat) == 1
    assert rm.groupChat[0].role == "WikiAgent"
    assert rm.groupChat[0].message == "Found it"


def test_get_last_reviewed_message() -> None:
    rm = ResponseMessage()
    rm.add_group_agent_message("WikiAgent", "some text")
    rm.add_group_agent_message("ReviewerAgent", "review 1 TERMINATE")
    rm.add_group_agent_message("ReviewerAgent", "review 2 TERMINATE")
    result = rm.get_last_reviewed_message()
    assert result is not None
    assert result.role == "ReviewerAgent"
    assert "TERMINATE" not in result.message
    assert result.message == "review 2 "


def test_get_last_reviewed_message_no_reviewer_raises() -> None:
    """When no ReviewerAgent messages exist, get_last_reviewed_message
    tries to access .message on None, raising AttributeError."""
    rm = ResponseMessage()
    rm.add_group_agent_message("WikiAgent", "some text")
    with pytest.raises(AttributeError):
        rm.get_last_reviewed_message()
