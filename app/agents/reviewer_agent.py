from semantic_kernel import Kernel
from semantic_kernel.agents.chat_completion.chat_completion_agent import (
    ChatCompletionAgent,
)
from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)

from app.core.config_factory import get_config


class ReviewerAgent:
    def __init__(self, instructions: str = ""):
        self.name = "ReviewerAgent"
        self.description = (
            "A reviewer agent that reviews the answers of other agents and "
            "reviews if everything is correct and sumarizes the response."
        )
        self.instructions = instructions
        self.config = get_config()

    def build_agent(self) -> ChatCompletionAgent:
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(
                deployment_name=self.config.REVIEWER_DEPLOYMENT_NAME,
                api_key=self.config.REVIEWER_API_KEY,
                base_url=self.config.REVIEWER_BASE_URL,
                api_version=self.config.REVIEWER_API_VERSION,
            )
        )

        return ChatCompletionAgent(
            kernel=kernel,
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
