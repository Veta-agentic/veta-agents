import logging

import requests


class IssueData:
    def __init__(self, title: str, description: str, url: str):
        self.title = title
        self.description = description
        self.url = url


class IssuesCreationAccessor:
    def run_query(gh_token: str, query: dict, variables: dict) -> dict:
        headers = {"Authorization": f"Bearer {gh_token}", "Accept": "application/vnd.github+json"}
        url = "https://api.github.com/graphql"
        response = requests.post(url, json={"query": query, "variables": variables or {}}, headers=headers)
        response.raise_for_status()
        return response.json()

    def create_issue(
        self,
        gh_token: str,
        gh_repo: str,
        title: str,
        description: str,
        labels: list[str] | None = None,
        assignee: str | None = None,
    ) -> IssueData | None:
        if not title:
            logging.error("Título vacío: no se puede crear el issue.")
            return None

        repo_query = """
        query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            id
        }
        }
        """
        owner, name = gh_repo.split("/")
        repo_data = IssuesCreationAccessor.run_query(gh_token, repo_query, {"owner": owner, "name": name})
        repo_id = repo_data["data"]["repository"]["id"]
        logging.info(f"Repository ID: {repo_id}")

        # 2. Get Copilot agent ID
        actor_query = """
        query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            suggestedActors(capabilities: [CAN_BE_ASSIGNED], first: 100) {
            nodes {
                login
                __typename
                ... on Bot { id }
                ... on User { id }
            }
            }
        }
        }
        """
        actor_data = IssuesCreationAccessor.run_query(gh_token, actor_query, {"owner": owner, "name": name})
        copilot_id = None
        for node in actor_data["data"]["repository"]["suggestedActors"]["nodes"]:
            if node["login"].startswith("copilot-"):
                copilot_id = node["id"]
                logging.info(f"Found Copilot agent: {node['login']}, ID: {copilot_id}")
                break

        if not copilot_id:
            logging.error("Copilot agent not found or not enabled for this repository.")
            return None
        # 3. Create the issue and assign Copilot
        create_issue_mutation = """
        mutation($repositoryId: ID!, $title: String!, $body: String!, $assigneeIds: [ID!]) {
        createIssue(input: {
            repositoryId: $repositoryId,
            title: $title,
            body: $body,
            assigneeIds: $assigneeIds
        }) {
            issue {
            url
            title
            assignees(first: 10) { nodes { login } }
            }
        }
        }
        """
        variables = {"repositoryId": repo_id, "title": title, "body": description, "assigneeIds": [copilot_id]}
        issue_result = IssuesCreationAccessor.run_query(gh_token, create_issue_mutation, variables)
        issue_info = issue_result["data"]["createIssue"]["issue"]
        logging.info(f"Issue created: {issue_info['url']}")
        logging.info(f"Assigned to: {[a['login'] for a in issue_info['assignees']['nodes']]}")
        # if response.status_code == 201:
        #     data = response.json()
        #     issue_url = data.get("html_url", "")
        #     body_preview = (data.get("body") or "")[:100]
        #     issue = IssueData(
        #         title=data.get("title", ""),
        #         description=body_preview,
        #         url=issue_url,
        #     )
        #     logging.info(f"Issue creado correctamente: {issue_url}")
        #     return issue
        # Algunos códigos comunes: 401 (auth), 403 (rate limit), 422 (validación)
        return IssueData(Url=issue_info["url"], description=description[:100], title=title)
        # logging.error(
        #     "Fallo al crear issue (%s): %s",
        #     response.status_code,
        #     response.text[:500],  # evitar log gigante
        #
        # return None
