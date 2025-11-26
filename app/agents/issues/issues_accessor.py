import logging

import requests


class IssueData:
    def __init__(self, title: str, description: str, url: str):
        self.title = title
        self.description = description
        self.url = url


class IssuesAccessor:
    def search_issues(self, gh_token: str, gh_repo: str, query: str) -> list[IssueData]:
        headers = {
            "Authorization": f"Bearer {gh_token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

        url = "https://api.github.com/search/issues"
        params = {"q": f"is:issue repo:{gh_repo} {query}"}  # Filtering by repository

        # Send the request to GitHub API
        response = requests.get(url, headers=headers, params=params)
        issuedata: list[IssueData] = []
        if response.status_code == 200:
            data = response.json()
            issues = data.get("items", [])
            if issues:
                logging.info(f"Found {len(issues)} related issues for '{query}':")
                for issue in issues:
                    issuedata.append(
                        IssueData(
                            title=issue["title"],
                            description=issue["body"][:100],
                            url=issue["html_url"],
                        )
                    )
                    logging.debug(f"Title: {issue['title']}")
                    logging.debug(f"Description: {issue['body'][:100]}...")  # Show first 100 characters
                    logging.debug(f"Link: {issue['html_url']}")
            else:
                logging.info(f"No related issues found for '{query}'.")
        else:
            logging.error(f"Error in query: {response.status_code}, {response.text}")
        return issuedata
