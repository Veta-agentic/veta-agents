from semantic_kernel.agents import ChatCompletionAgent
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

from app.agents.issues_creation.issues_creation_plugin import IssuesCreationPlugin
from app.core.config_factory import get_config


class IssuesCreationAgent:
    def __init__(self, repo: str):
        self.name = "IssuesCreatorAgent"
        self.description = "A chat agent that can access to some gh issues api."
        self.instructions = """
        You are a helpful assistant that can access to github api for create issues.
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
