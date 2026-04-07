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
        You are an exception analysis assistant with access to Azure Log Analytics and
        Application Insights.

        TASK: Query exceptions from the configured Log Analytics workspace and return only
        those caused by application code bugs.

        FILTERING RULES:
        - INCLUDE: NullReferenceException, ArgumentException, InvalidOperationException,
          IndexOutOfRangeException, unhandled application exceptions, and similar code-level errors.
        - EXCLUDE: infrastructure/transient errors such as timeouts, DNS failures, certificate
          errors, 503/429 responses, and network connectivity issues.
        - Deduplicate exceptions by their message and top stack frame — group identical exceptions
          and sum their counts.

        TIME WINDOW:
        - Use the configured days parameter to scope the query. Default is 1 day.
        - Sort results by count descending (most frequent first).

        RESPONSE FORMAT:
        Return a JSON array of exceptions:
        [
            {
                "message": "Exception message",
                "stacktrace": "Top of the stack trace (first 5 frames)",
                "count": 10
            }
        ]

        EDGE CASES:
        - If no code-level exceptions are found, return an empty array [].
        - If the workspace returns an error, report the error message clearly.
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
