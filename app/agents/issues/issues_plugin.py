from semantic_kernel.functions import kernel_function

from app.agents.issues.issues_accessor import IssueData, IssuesAccessor


class IssuesPlugin:
    PLUGIN_NAME = "GhIssuesSearch"
    DESCRIPTION = "A plugin that allows you to search for similar questions in a ghthe github issues repo issues."

    def __init__(self, repo: str, gh_token: str):
        self.repo = repo
        self.gh_token = gh_token

    @kernel_function(
        name="get_issues_content",
        description="Gets a list of issues from a the github issues repo",
    )
    def get_content(self, query: str) -> str:
        issue_accessor = IssuesAccessor()
        docs: list[IssueData] = issue_accessor.search_issues(gh_token=self.gh_token, gh_repo=self.repo, query=query)
        return docs[0].url
