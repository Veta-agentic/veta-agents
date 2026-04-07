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
    user: str | None = None
    githubWikis: list[str]
    githubWikiBaseImageUrl: str
    githubRepo: str
    sessionId: str | None = None
    historyMessages: list[HistoryMessageModel] | None = None


class ExceptionWatchRequestModel(BaseSchema):
    azure_log_analytics_workspace_id: str
    azure_client_id: str | None = None
    azure_tenant_id: str | None = None
    azure_client_secret: str | None = None
    days: int | None = 1
    user: str | None = None
    github_repo: str
    sessionId: str | None = None
    historyMessages: list[HistoryMessageModel] | None = None


class ResponseModel(BaseModel):
    answer: str
    historyMessages: list[HistoryMessageModel]
    agentsGroupChat: list[HistoryMessageModel]
    sources: list[str] | None
    suggestions: list[str] | None
    prompt_tokens: str | None = "0"
    completion_tokens: str | None = "0"
