from semantic_kernel.functions import kernel_function

from app.agents.exceptions.exception_accessor import ExceptionAccessor, ExceptionData


class ExceptionPlugin:
    PLUGIN_NAME = "ExceptionPlugin"
    DESCRIPTION = "A plugin that downloads Exceptions from Log Analytics workspaces and returns the details."

    def __init__(
        self, azure_tenant: str, azure_client_id: str, azure_client_secret: str, log_workspace_id: str, days: int
    ):
        self.azure_client_id = azure_client_id
        self.azure_client_secret = azure_client_secret
        self.azure_tenant = azure_tenant
        self.log_workspace_id = log_workspace_id
        self.days = days

    @kernel_function(
        name="download_exceptions",
        description="""Given a list of images,
           download the images and returns the an object with the url,
           and base64 content processed fields.""",
    )
    def download_exceptions(self) -> list[ExceptionData]:
        """
        Given a logAnalytics workspace ID and a number of days, download the exceptions and returns the an object with
        the details like message, stacktrace and count fields.
        """
        return ExceptionAccessor.get_exceptions_from_loganalytics(
            azure_client_id=self.azure_client_id,
            azure_client_secret=self.azure_client_secret,
            azure_tenant=self.azure_tenant,
            log_workspace_id=self.log_workspace_id,
            days=self.days,
        )
