from semantic_kernel.agents import ChatCompletionAgent
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

from app.agents.issues.issues_plugin import IssuesPlugin
from app.core.config_factory import get_config


class IssuesAgent:
    def __init__(self, repo: str):
        self.name = "IssuesAgent"
        self.description = "A chat agent that can access to some gh issues api."
        self.instructions = """
        You are a GitHub issues search assistant with access to the GitHub Issues API.

        TASK: Search for issues in the repository that are similar to the user's question and
        explain how they were resolved.

        SEARCH STRATEGY:
        - Extract key terms from the question (error messages, component names, symptoms).
        - Search both open and closed issues for matches.
        - Prioritize closed/resolved issues since they contain solutions.
        - Return at most 5 of the most relevant results.

        RESPONSE FORMAT:
        Return a JSON array of matching issues. Each entry must include the issue URL and title:
        [
            {"url": "https://github.com/owner/repo/issues/123", "title": "Issue title"},
            {"url": "https://github.com/owner/repo/issues/456", "title": "Issue title"}
        ]

        EDGE CASES:
        - If no matching issues are found, return an empty array [] and state that no similar
          issues were found.
        - If the search query is too vague, do your best with available terms — do not ask
          the user for clarification.
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
            plugins=[IssuesPlugin(repo=self.repo, gh_token=self.config.GH_TOKEN)],
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
