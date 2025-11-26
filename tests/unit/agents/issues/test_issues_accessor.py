from unittest.mock import MagicMock, patch

from app.agents.issues.issues_accessor import IssuesAccessor


@patch("app.agents.issues.issues_accessor.requests.get")
def test_search_issues_success(mock_get: MagicMock) -> None:
    # Mock GitHub API response
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "items": [
            {
                "title": "Issue 1",
                "body": "Description of issue 1",
                "html_url": "http://example.com/issue1",
            },
            {
                "title": "Issue 2",
                "body": "Description of issue 2",
                "html_url": "http://example.com/issue2",
            },
        ]
    }
    mock_get.return_value = mock_response

    accessor = IssuesAccessor()
    gh_token = "fake_token"
    gh_repo = "user/repo"
    query = "bug"

    result = accessor.search_issues(gh_token, gh_repo, query)

    assert len(result) == 2
    assert result[0].title == "Issue 1"
    assert result[0].description == "Description of issue 1"
    assert result[0].url == "http://example.com/issue1"
    assert result[1].title == "Issue 2"
    assert result[1].description == "Description of issue 2"
    assert result[1].url == "http://example.com/issue2"


@patch("app.agents.issues.issues_accessor.requests.get")
def test_search_issues_no_results(mock_get: MagicMock) -> None:
    # Mock GitHub API response with no issues
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"items": []}
    mock_get.return_value = mock_response

    accessor = IssuesAccessor()
    gh_token = "fake_token"
    gh_repo = "user/repo"
    query = "nonexistent"

    result = accessor.search_issues(gh_token, gh_repo, query)

    assert len(result) == 0


@patch("app.agents.issues.issues_accessor.requests.get")
def test_search_issues_error_response(mock_get: MagicMock) -> None:
    # Mock GitHub API error response
    mock_response = MagicMock()
    mock_response.status_code = 404
    mock_response.text = "Not Found"
    mock_get.return_value = mock_response

    accessor = IssuesAccessor()
    gh_token = "fake_token"
    gh_repo = "user/repo"
    query = "bug"

    result = accessor.search_issues(gh_token, gh_repo, query)

    assert len(result) == 0
