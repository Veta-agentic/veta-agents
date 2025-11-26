from semantic_kernel.agents.chat_completion.chat_completion_agent import (
    ChatCompletionAgent,
)
from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)
from semantic_kernel.kernel import Kernel

from app.agents.issues.issues_plugin import IssuesPlugin
from app.core.config_factory import get_config


class IssuesAgent:
    def __init__(self, repo: str):
        self.name = "IssuesAgent"
        self.description = "A chat agent that can access to some gh issues api."
        self.instructions = """
        You are a helpful assistant that can access to some github issues api for search similar questions
        inside the issues and return how this issues are resolved.
        Add the links of the issues related and solved in the past.
        If you can't find the answer, say that you can't find the answer.
        The response SHOULD be a json object like
         [
         {"url": "yoururlfromghIssuesretrievedinformation",
         "title": "the issue Title"},
         {"url": "yoururlfromghIssuesretrievedinformation",
         "title": "the issue Title" }]
        """
        self.config = get_config()
        self.repo = repo

    def build_agent(self) -> ChatCompletionAgent:
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(
                deployment_name=self.config.ISSUES_DEPLOYMENT_NAME,
                api_key=self.config.ISSUES_API_KEY,
                base_url=self.config.ISSUES_BASE_URL,
                api_version=self.config.ISSUES_API_VERSION,
            )
        )
        kernel.add_plugin(
            IssuesPlugin(
                repo=self.repo,
                gh_token=self.config.GH_TOKEN,
            ),
            plugin_name=IssuesPlugin.PLUGIN_NAME,
        )

        return ChatCompletionAgent(
            kernel=kernel,
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
