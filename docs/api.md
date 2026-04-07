# API & Models

All endpoints require an `X-API-Key` header. Interactive documentation is available at `/docs` (Swagger UI).

## Endpoints

### `POST /ask` — Q&A from wiki and issue context

Coordinates **WikiAgent**, **IssuesAgent**, **ImagesAgent**, and **ReviewerAgent** to produce a synthesized Markdown answer.

#### Request Body (`RequestModel`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question` | string | Yes | The user's question |
| `githubWikis` | string[] | Yes | List of wiki page URLs to use as context |
| `githubWikiBaseImageUrl` | string | Yes | Base URL for resolving relative image paths in wiki content |
| `githubRepo` | string | Yes | GitHub repo in `owner/repo` format for issue search |
| `user` | string | No | User identifier |
| `sessionId` | string | No | Session identifier for tracking |
| `historyMessages` | HistoryMessageModel[] | No | Prior conversation history |

#### Example Request

```bash
curl -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -H "X-API-Key: my-local-key" \
  -d '{
    "question": "How do I configure the Infrastructure Dashboard?",
    "githubWikis": [
      "https://github.com/Azure/CCOInsights/wiki/Infrastructure-Dashboard",
      "https://github.com/Azure/CCOInsights/wiki/Infrastructure-Dashboard-Deployment%20Guide"
    ],
    "githubWikiBaseImageUrl": "https://github.com/Azure/CCOInsights/wiki/",
    "githubRepo": "azure/ccoinsights"
  }'
```

#### Example Response (`ResponseModel`)

```json
{
  "answer": "🤖 ## Response\nHere is how to configure the Infrastructure Dashboard...\n\n## Wiki References\n- [Deployment Guide](https://github.com/Azure/CCOInsights/wiki/Infrastructure-Dashboard-Deployment%20Guide)\n\n## Issues Related\n- [#42 Dashboard refresh issue](https://github.com/azure/ccoinsights/issues/42)",
  "historyMessages": [
    {"role": "user", "message": "How do I configure the Infrastructure Dashboard?"}
  ],
  "agentsGroupChat": [
    {"role": "WikiAgent", "message": "[{\"url\": \"...\", \"content\": \"...\"}]"},
    {"role": "IssuesAgent", "message": "[{\"url\": \"...\", \"title\": \"...\"}]"},
    {"role": "ImagesAgent", "message": "[{\"url\": \"...\", \"content\": \"...\"}]"},
    {"role": "ReviewerAgent", "message": "🤖 ## Response\n..."}
  ],
  "sources": ["Infrastructure-Dashboard.md", "Deployment-Guide.md"],
  "suggestions": ["Check the Troubleshooting Guide for refresh issues"],
  "prompt_tokens": "1200",
  "completion_tokens": "450"
}
```

---

### `POST /fix/exceptions` — Detect exceptions and create GitHub issues

Coordinates **ExceptionsAgent**, **IssuesCreationAgent**, and **ReviewerAgent** to find recent production exceptions and create issues.

#### Request Body (`ExceptionWatchRequestModel`)

> **Note:** This model uses Pydantic alias generators — **camelCase** for request validation, **PascalCase** for serialized output.

| Field (camelCase) | Type | Required | Description |
|-------------------|------|----------|-------------|
| `azureLogAnalyticsWorkspaceId` | string | Yes | Log Analytics Workspace ID (GUID) |
| `azureClientId` | string | Yes* | Service principal client ID for Azure auth |
| `azureTenantId` | string | Yes* | Azure AD tenant ID |
| `azureClientSecret` | string | Yes* | Service principal client secret |
| `days` | int | No | Number of days to look back (default: `1`) |
| `user` | string | No | User identifier |
| `githubRepo` | string | Yes | Target repo where issues are created (`owner/repo`) |
| `sessionId` | string | No | Session identifier |
| `historyMessages` | HistoryMessageModel[] | No | Prior conversation history |

> \* Azure credentials are required when using explicit service principal authentication.

#### Example Request

```bash
curl -X POST http://localhost:8000/fix/exceptions \
  -H "Content-Type: application/json" \
  -H "X-API-Key: my-local-key" \
  -d '{
    "azureLogAnalyticsWorkspaceId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "azureClientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "azureTenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "azureClientSecret": "your-client-secret",
    "days": 1,
    "githubRepo": "ORG/REPO"
  }'
```

#### Example Response

```json
{
  "answer": "## Workflow Summary\n\n**Exceptions found:** 3\n**Issues created:** 2\n\n1. [NullReferenceException in UserService](https://github.com/ORG/REPO/issues/15) — assigned to copilot\n2. [TimeoutException in PaymentGateway](https://github.com/ORG/REPO/issues/16) — assigned to copilot\n\n1 exception was already tracked in issue #12.",
  "historyMessages": [
    {"role": "user", "message": "Search for exceptions in the last 24 hours and report them as issues if needed."}
  ],
  "agentsGroupChat": [
    {"role": "ExceptionsAgent", "message": "[{\"message\": \"NullReferenceException\", ...}]"},
    {"role": "IssuesCreatorAgent", "message": "Created issue #15..."},
    {"role": "ReviewerAgent", "message": "## Workflow Summary\n..."}
  ],
  "sources": null,
  "suggestions": null,
  "prompt_tokens": "800",
  "completion_tokens": "320"
}
```

---

### Other Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/docs` | GET | No | Swagger UI — interactive API explorer |
| `/openapi.json` | GET | No | OpenAPI 3.x schema (JSON) |

---

## Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success — payload is a `ResponseModel` |
| `401` | Missing or invalid `X-API-Key` header |
| `422` | Validation error — request body doesn't match the schema (FastAPI auto-generated) |
| `500` | Unexpected server error — caught by the route handler or middleware |

---

## Internal Models

### `HistoryMessageModel`

```json
{ "role": "string", "message": "string" }
```

Used in both request (`historyMessages`) and response (`historyMessages`, `agentsGroupChat`).

### `ResponseModel`

| Field | Type | Description |
|-------|------|-------------|
| `answer` | string | Final Markdown answer from ReviewerAgent |
| `historyMessages` | HistoryMessageModel[] | Conversation history including the new exchange |
| `agentsGroupChat` | HistoryMessageModel[] | Full agent-by-agent conversation log |
| `sources` | string[] \| null | Wiki page references used |
| `suggestions` | string[] \| null | Follow-up suggestions |
| `prompt_tokens` | string | Total prompt tokens consumed across all agents |
| `completion_tokens` | string | Total completion tokens consumed |

### Alias Behavior

`ExceptionWatchRequestModel` uses Pydantic's `AliasGenerator`:
- **Validation** (incoming JSON): `camelCase` — e.g., `azureLogAnalyticsWorkspaceId`
- **Serialization** (outgoing JSON): `PascalCase` — e.g., `AzureLogAnalyticsWorkspaceId`

If you're building a client integration, be aware of both formats.

## OpenAPI

- **Swagger UI:** `http://localhost:8000/docs`
- **OpenAPI JSON:** `http://localhost:8000/openapi.json`

### VS Code REST Client

Example `.rest` files are in the `samples/` folder. They use `{{$dotenv VAR_NAME}}` syntax to pull values from your `.env` file:

```http
@host=http://localhost:8000
POST {{host}}/ask
Content-Type: application/json
X-API-Key: {{$dotenv API_KEYS}}

{
  "question": "How do I configure auto-refresh?",
  "githubWikis": ["https://github.com/ORG/REPO/wiki/Setup"],
  "githubWikiBaseImageUrl": "https://github.com/ORG/REPO/wiki/",
  "githubRepo": "ORG/REPO"
}
```
