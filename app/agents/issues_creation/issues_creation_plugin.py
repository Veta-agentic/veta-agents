from semantic_kernel.functions import kernel_function

from app.agents.issues_creation.issues_creation_accessor import IssueData, IssuesCreationAccessor


class IssuesCreationPlugin:
    PLUGIN_NAME = "GhIssuesCreator"
    DESCRIPTION = "A plugin that create issues in a github repository issues."

    def __init__(self, repo: str, gh_token: str):
        self.repo = repo
        self.gh_token = gh_token

    @kernel_function(
        name="create_issue",
        description="create a new issue in the github repository issues.",
    )
    def create_issue(self, title: str, description: str, labels: str, assignee: str) -> str:
        issue_accessor = IssuesCreationAccessor()
        docs: list[IssueData] = issue_accessor.create_issue(
            gh_token=self.gh_token,
            gh_repo=self.repo,
            title=title,
            description=description,
            labels=labels,
            assignee=assignee,
        )
        return docs[0].url
