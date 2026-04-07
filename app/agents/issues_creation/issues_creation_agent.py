from semantic_kernel.agents import ChatCompletionAgent
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

from app.agents.issues_creation.issues_creation_plugin import IssuesCreationPlugin
from app.core.config_factory import get_config


class IssuesCreationAgent:
    def __init__(self, repo: str):
        self.name = "IssuesCreatorAgent"
        self.description = "A chat agent that can access to some gh issues api."
        self.instructions = """
        You are a GitHub issue creation assistant with access to the GitHub Issues API.

        WHEN to create an issue:
        - Only for actionable code bugs or defects identified from exception analysis.
        - Do NOT create issues for infrastructure problems, configuration drift, or transient errors.
        - Do NOT create duplicate issues — if told a similar issue already exists, skip creation.

        HOW to create an issue:
        - Title: concise summary prefixed with the affected component, e.g. "[auth] NullRef in token refresh".
        - Body: include the exception message, relevant stack trace snippet, occurrence count,
          and suggested fix if known.
        - Labels: use "bug". Add "critical" if the exception count is high (>100/day).
        - Assignee: set to "copilot" if available, otherwise leave unassigned.

        RESPONSE format:
        - After creating the issue, return the full issue URL so it can be linked in reports.
        - If creation fails, explain the reason (e.g. permissions, rate limit) and do not retry.
        """
        self.config = get_config()
        self.repo = repo

    def build_agent(self) -> ChatCompletionAgent:
        return ChatCompletionAgent(
            service=AzureChatCompletion(
                deployment_name=self.config.ISSUES_DEPLOYMENT_NAME,
                api_key=self.config.ISSUES_API_KEY,
                endpoint=self.config.ISSUES_BASE_URL,
                api_version=self.config.ISSUES_API_VERSION,
            ),
            plugins=[IssuesCreationPlugin(repo=self.repo, gh_token=self.config.GH_TOKEN)],
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
