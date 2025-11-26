from typing import Optional

from pydantic import AliasGenerator, BaseModel, ConfigDict
from pydantic.alias_generators import to_camel, to_pascal


class BaseSchema(BaseModel):
    model_config = ConfigDict(
        alias_generator=AliasGenerator(
            validation_alias=to_camel,
            serialization_alias=to_pascal,
        )
    )


class HistoryMessageModel(BaseModel):
    role: str
    message: str


class RequestModel(BaseModel):
    question: str
    user: Optional[str] = None
    githubWikis: list[str]
    githubWikiBaseImageUrl: str
    githubRepo: str
    sessionId: Optional[str] = None
    historyMessages: Optional[list[HistoryMessageModel]] = None


class ExceptionWatchRequestModel(BaseSchema):
    azure_log_analytics_workspace_id: str
    azure_client_id: Optional[str] = None
    azure_tenant_id: Optional[str] = None
    azure_client_secret: Optional[str] = None
    days: Optional[int] = 1
    user: Optional[str] = None
    github_repo: str
    sessionId: Optional[str] = None
    historyMessages: Optional[list[HistoryMessageModel]] = None


class ResponseModel(BaseModel):
    answer: str
    historyMessages: list[HistoryMessageModel]
    agentsGroupChat: list[HistoryMessageModel]
    sources: Optional[list[str]]
    suggestions: Optional[list[str]]
    prompt_tokens: Optional[str] = "0"
    completion_tokens: Optional[str] = "0"
