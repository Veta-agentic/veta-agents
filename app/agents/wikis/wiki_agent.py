from typing import Optional

from semantic_kernel.agents.chat_completion.chat_completion_agent import (
    ChatCompletionAgent,
)
from semantic_kernel.connectors.ai.open_ai import AzureChatPromptExecutionSettings
from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)
from semantic_kernel.functions.kernel_arguments import KernelArguments
from semantic_kernel.kernel import Kernel

from app.agents.wikis.wiki_plugin import WikiPlugin
from app.core.config_factory import get_config


class WikiAgent:
    def __init__(self, wiki_urls: Optional[list[str]] = None, base_url_images: Optional[str] = None):
        self.name = "WikiAgent"
        self.description = "A chat agent that can access to some wiki pages."
        self.instructions = """
        You are a helpful assistant that can download information from wiki pages, this pages have an URL and CONTENT
        Your mission is to provide the correct Context for anwer the question.
        Add Always the reference to the URL with the content.
        Add Images from the CONTENT in markdown lik screenshots from the CONTENT
        If you don't know the answer, just say that you don't know.
        The response SHOULD be a json object like:
        [
        {"url": "yoururlfromwikiretrievedinformation",
          "content": "the content retrieved that gives context to the question" },
         {"url": "yoururlfromwikiretrievedinformation",
         "content": "the content retrieved that gives context to the question"
         }]
        .
        """
        self.wiki_urls = wiki_urls or []
        self.base_url_images = base_url_images or None
        self.config = get_config()

    def build_agent(self) -> ChatCompletionAgent:
        settings = AzureChatPromptExecutionSettings()
        # settings.response_format = WikiContents
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(
                deployment_name=self.config.WIKIS_DEPLOYMENT_NAME,
                api_key=self.config.WIKIS_API_KEY,
                base_url=self.config.WIKIS_BASE_URL,
                api_version=self.config.WIKIS_API_VERSION,
            )
        )
        kernel.add_plugin(
            WikiPlugin(wiki_urls=self.wiki_urls, base_url_images=self.base_url_images),
            plugin_name=WikiPlugin.PLUGIN_NAME,
        )

        return ChatCompletionAgent(
            kernel=kernel,
            name=self.name,
            description=self.description,
            instructions=self.instructions,
            arguments=KernelArguments(settings=settings),
        )
