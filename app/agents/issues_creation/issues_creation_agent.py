from semantic_kernel.agents.chat_completion.chat_completion_agent import (
    ChatCompletionAgent,
)
from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)
from semantic_kernel.kernel import Kernel

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
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(
                deployment_name=self.config.ISSUES_DEPLOYMENT_NAME,
                api_key=self.config.ISSUES_API_KEY,
                endpoint=self.config.ISSUES_BASE_URL,
                api_version=self.config.ISSUES_API_VERSION,
            )
        )
        kernel.add_plugin(
            IssuesCreationPlugin(
                repo=self.repo,
                gh_token=self.config.GH_TOKEN,
            ),
            plugin_name=IssuesCreationPlugin.PLUGIN_NAME,
        )

        return ChatCompletionAgent(
            kernel=kernel,
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
