class HistoryMessage:
    def __init__(self, role: str, message: str):
        self.role = role
        self.message = message


class ResponseMessage:
    def __init__(self):
        self.answer: str = ""
        self.historyMessages: list[HistoryMessage] = []
        self.groupChat: list[HistoryMessage] = []
        self.sources: list[str] = []
        self.suggestions: list[str] = []
        self.prompt_tokens = 0
        self.completion_tokens = 0

    def add_assistant_message(self, message: str) -> None:
        self.historyMessages.append(HistoryMessage(role="assistant", message=message))

    def add_group_agent_message(self, assistant_name: str, message: str) -> None:
        self.groupChat.append(HistoryMessage(role=assistant_name, message=message))

    def add_user_message(self, message: str) -> None:
        self.historyMessages.append(HistoryMessage(role="user", message=message))

    def get_last_reviewed_message(self) -> HistoryMessage | None:
        reviewed_messages = [msg for msg in self.groupChat if msg.role == "ReviewerAgent"]
        last_message = reviewed_messages[-1] if reviewed_messages else None
        last_message.message = last_message.message.replace("TERMINATE", "") if last_message else None
        return last_message
