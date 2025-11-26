# API & Models

## Endpoints

### POST `/ask`
RequestModel fields:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| question | string | Yes | User question |
| user | string | No | Optional user identifier |
| githubWikis | string[] | Yes | List of wiki URLs to use |
| githubWikiBaseImageUrl | string | Yes | Base URL to resolve wiki images |
| githubRepo | string | Yes | `owner/repo` GitHub repo for issue search |
| sessionId | string | No | Session identifier |
| historyMessages | HistoryMessageModel[] | No | Prior conversation history |

Example:
```json
{
  "question": "How do I configure FastAPI?",
  "githubWikis": ["https://raw.githubusercontent.com/ORG/REPO/wiki/fastapi.md"],
  "githubWikiBaseImageUrl": "https://raw.githubusercontent.com/ORG/REPO/wiki/images",
  "githubRepo": "ORG/REPO"
}
```

Response (`ResponseModel`):
```json
{
  "answer": "Markdown...",
  "historyMessages": [{"role": "user", "message": "..."}],
  "agentsGroupChat": [{"role": "ReviewerAgent", "message": "..."}],
  "sources": ["wiki1.md"],
  "suggestions": ["Explore X"],
  "prompt_tokens": "1200",
  "completion_tokens": "450"
}
```

### POST `/fix/exceptions`
`ExceptionWatchRequestModel` (validation camelCase, serialization PascalCase):
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| azureLogAnalyticsWorkspaceId | string | Yes | Log Analytics Workspace ID (GUID) |
| azureClientId | string | Yes* | Client ID (when explicit credential is needed) |
| azureTenantId | string | Yes* | Tenant ID |
| azureClientSecret | string | Yes* | Client Secret |
| days | int | No | Number of days back (default 1) |
| user | string | No | User identifier |
| githubRepo | string | Yes | Target repo where issues are created |
| sessionId | string | No | Session identifier |
| historyMessages | HistoryMessageModel[] | No | Conversation history |

Example:
```json
{
  "azureLogAnalyticsWorkspaceId": "xxxx-xxxx-xxxx-xxxx",
  "azureClientId": "yyyy-yyyy",
  "azureTenantId": "zzzz-zzzz",
  "azureClientSecret": "SECRET",
  "days": 1,
  "githubRepo": "ORG/REPO"
}
```

### Status Codes
- 200: Successful operation (payload is a `ResponseModel`).
- 401: API Key failure (auth middleware).
- 422: Validation error (FastAPI).
- 500: Unexpected error (caught and returned with generic message).

## Internal Models
`HistoryMessageModel`: `{ role: string, message: string }`

Alias: `AliasGenerator` is used (camelCase validation, PascalCase serialization) in `ExceptionWatchRequestModel`; document both formats if integrating other clients.

## OpenAPI
Available at `/openapi.json` and `http://localhost:8000/docs`.
