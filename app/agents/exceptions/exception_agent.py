from semantic_kernel.agents import ChatCompletionAgent
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

from app.agents.exceptions.exception_plugin import ExceptionPlugin
from app.core.config_factory import get_config


class ExceptionsAgent:
    def __init__(
        self, azure_tenant: str, azure_client_id: str, azure_client_secret: str, log_workspace_id: str, days: int = 1
    ):
        self.name = "ExceptionsAgent"
        self.description = "A chat agent that can access to logAnalytics workspaces."
        self.instructions = """
        You are a helpful assistant that can access to logAnalytics for search exceptions
        inside the Applications that are connected to AppInsights and LogAnalytics. You MUST
        identify the exceptions that are happening because are errors in the code and return them.
        Return a list of exceptions with the message, stacktrace and count fields.
        Use a schema like this one:
        [
            {
                "message": "Exception message",
                "stacktrace": "Exception stacktrace",
                "count": 10
            }
        ]
        """
        self.config = get_config()
        self.azure_tenant = azure_tenant
        self.azure_client_id = azure_client_id
        self.azure_client_secret = azure_client_secret
        self.log_workspace_id = log_workspace_id
        self.days = days

    def build_agent(self) -> ChatCompletionAgent:
        return ChatCompletionAgent(
            service=AzureChatCompletion(
                deployment_name=self.config.IMAGES_DEPLOYMENT_NAME,
                api_key=self.config.IMAGES_API_KEY,
                endpoint=self.config.IMAGES_BASE_URL,
                api_version=self.config.WIKIS_API_VERSION,
            ),
            plugins=[
                ExceptionPlugin(
                    azure_tenant=self.azure_tenant,
                    azure_client_id=self.azure_client_id,
                    azure_client_secret=self.azure_client_secret,
                    log_workspace_id=self.log_workspace_id,
                    days=self.days,
                )
            ],
            name=self.name,
            description=self.description,
            instructions=self.instructions,
        )
