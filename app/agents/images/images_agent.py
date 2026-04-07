from semantic_kernel.agents.chat_completion.chat_completion_agent import (
    ChatCompletionAgent,
)
from semantic_kernel.connectors.ai.open_ai.services.azure_chat_completion import (
    AzureChatCompletion,
)
from semantic_kernel.kernel import Kernel

from app.agents.images.images_plugin import ImagesPlugin
from app.core.config_factory import get_config


class ImagesAgent:
    def __init__(self):
        self.name = "ImagesAgent"
        self.description = """A chat agent that given one or some images,
         it generates the description of what is happening in those images."""
        self.instructions = """
        You are a helpful assistant that receives one or some links from user question in markdown format with images.
        FIRST Download the images in BASE64 and USE the content of the images,
        SECOND describe those images based in the BASE64Content,
        this description ADDS CONTEXT to the user QUESTION.
        The response SHOULD be a json object like:
        [{"url": "originalurlfromimage",
          "content": "the description of this image for add context to question" },
         {"url": "originalurlfromimage",
          "content": "the description of this image for add context to question" }]
        """
        self.config = get_config()

    def build_agent(self) -> ChatCompletionAgent:
        kernel = Kernel()
        kernel.add_service(
            AzureChatCompletion(
                deployment_name=self.config.IMAGES_DEPLOYMENT_NAME,
                api_key=self.config.IMAGES_API_KEY,
                endpoint=self.config.IMAGES_BASE_URL,
                api_version=self.config.WIKIS_API_VERSION,
            )
        )
        kernel.add_plugin(
            ImagesPlugin(),
            plugin_name=ImagesPlugin.PLUGIN_NAME,
        )

        return ChatCompletionAgent(
            kernel=kernel,
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
