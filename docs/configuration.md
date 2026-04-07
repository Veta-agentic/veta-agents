# Configuration & Environment Variables

## How Configuration Loads

The `config_factory.py` module uses a singleton pattern (thread-safe, cached) to load secrets once at startup:

```
ENVIRONMENT=dev  →  EnvSecretLoader  →  reads os.getenv() / .env file
ENVIRONMENT=*    →  KeyVaultSecretLoader  →  reads Azure Key Vault via DefaultAzureCredential
```

The factory is called via `get_config()` throughout the app. All agents, auth, and routes share the same `Config` instance.

## Required Variables

These are validated at startup by `Config._validate_secrets()`. If any are missing, the app raises `OSError` and refuses to start.

| Name | Description |
|------|-------------|
| `GH_TOKEN` | GitHub personal access token (scopes: `repo` or `public_repo`) |
| `IMAGES_DEPLOYMENT_NAME` | Azure OpenAI deployment name for the ImagesAgent |
| `IMAGES_API_KEY` | API key for the images model |
| `IMAGES_BASE_URL` | Azure OpenAI resource endpoint for images (see warning below) |
| `IMAGES_API_VERSION` | API version string (e.g., `2025-01-01-preview`) |
| `ISSUES_DEPLOYMENT_NAME` | Azure OpenAI deployment name for the IssuesAgent |
| `ISSUES_API_KEY` | API key for the issues model |
| `ISSUES_BASE_URL` | Azure OpenAI resource endpoint for issues |
| `ISSUES_API_VERSION` | API version string |
| `WIKIS_DEPLOYMENT_NAME` | Azure OpenAI deployment name for the WikiAgent |
| `WIKIS_API_KEY` | API key for the wikis model |
| `WIKIS_BASE_URL` | Azure OpenAI resource endpoint for wikis |
| `WIKIS_API_VERSION` | API version string |
| `REVIEWER_DEPLOYMENT_NAME` | Azure OpenAI deployment name for the ReviewerAgent |
| `REVIEWER_API_KEY` | API key for the reviewer model |
| `REVIEWER_BASE_URL` | Azure OpenAI resource endpoint for reviewer |
| `REVIEWER_API_VERSION` | API version string |

> **Tip:** All four agent groups (images, issues, wikis, reviewer) can point to the **same** Azure OpenAI resource and deployment. They have separate variables to allow independent scaling or model selection.

## ⚠️ Critical: `*_BASE_URL` Format

The `*_BASE_URL` variables must contain **only** the Azure OpenAI resource endpoint — **not** the full deployment URL.

```
✅ CORRECT:  https://my-resource.openai.azure.com/
❌ WRONG:    https://my-resource.openai.azure.com/openai/deployments/gpt-4o/chat/completions
```

**Why?** The app uses Semantic Kernel's `AzureChatCompletion` with the `endpoint=` parameter, which **auto-constructs** the full URL from the resource endpoint + deployment name + API version. If you provide a full path, the URL will be double-constructed and result in **404 errors**.

See the [Architecture — Key Bug Fixes](architecture.md#key-bug-fixes) section for full details.

## Application Variables

| Name | Description | Default |
|------|-------------|---------|
| `ENVIRONMENT` | `dev` → env variables; anything else → Key Vault | `prod` |
| `KEYVAULT_NAME` | Azure Key Vault name (required when `ENVIRONMENT ≠ dev`) | — |
| `API_KEYS` | Comma-separated API keys for `X-API-Key` auth | — |
| `APPINSIGHTS_CONNECTION_STRING` | Application Insights connection string (enables OpenTelemetry) | — |

## Log Analytics Variables (for `/fix/exceptions`)

These can be set in the `.env` file **or** passed per-request in the POST body:

| Name | Description |
|------|-------------|
| `AZURE_LA_WORKSPACEID` | Log Analytics Workspace ID (GUID) |
| `AZURE_CLIENT_ID` | Service principal client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_CLIENT_SECRET` | Service principal secret |

## Full `.env.sample`

```env
# ── App ──────────────────────────────────────────
API_KEYS=xxx-xxx-xxx-xxx-xxx
KEYVAULT_NAME=MyawesomeKeyVault
ENVIRONMENT=dev
APPINSIGHTS_CONNECTION_STRING=

# ── GitHub ───────────────────────────────────────
GH_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXX

# ── Azure OpenAI (per agent) ────────────────────
# ⚠️  *_BASE_URL = resource endpoint only!
#     Example: https://my-resource.openai.azure.com/
IMAGES_DEPLOYMENT_NAME=gpt-4o
IMAGES_API_KEY=
IMAGES_BASE_URL=
IMAGES_API_VERSION=2025-01-01-preview

ISSUES_DEPLOYMENT_NAME=gpt-4o
ISSUES_API_KEY=
ISSUES_BASE_URL=
ISSUES_API_VERSION=2025-01-01-preview

WIKIS_DEPLOYMENT_NAME=gpt-4o
WIKIS_API_KEY=
WIKIS_BASE_URL=
WIKIS_API_VERSION=2025-01-01-preview

REVIEWER_DEPLOYMENT_NAME=gpt-4o
REVIEWER_API_KEY=
REVIEWER_BASE_URL=
REVIEWER_API_VERSION=2025-01-01-preview

# ── Log Analytics (for /fix/exceptions) ──────────
AZURE_LA_WORKSPACEID=
AZURE_CLIENT_ID=
AZURE_TENANT_ID=
AZURE_CLIENT_SECRET=
```

## Production: Key Vault Setup

In production (`ENVIRONMENT != dev`), the app uses `KeyVaultSecretLoader` which:

1. Builds the vault URL: `https://{KEYVAULT_NAME}.vault.azure.net/`
2. Authenticates via `DefaultAzureCredential` (typically the Web App's system-assigned managed identity).
3. Reads secrets by name (hyphenated keys, e.g., `gh-token` → converted to `GH_TOKEN` internally).

**Key Vault secret names → Config attribute mapping:**

| Key Vault Secret Name | Config Attribute |
|-----------------------|------------------|
| `gh-token` | `GH_TOKEN` |
| `api-keys` | `API_KEYS` |
| `images-deployment-name` | `IMAGES_DEPLOYMENT_NAME` |
| `images-api-key` | `IMAGES_API_KEY` |
| `images-base-url` | `IMAGES_BASE_URL` |
| `images-api-version` | `IMAGES_API_VERSION` |
| `issues-deployment-name` | `ISSUES_DEPLOYMENT_NAME` |
| `issues-api-key` | `ISSUES_API_KEY` |
| `issues-base-url` | `ISSUES_BASE_URL` |
| `issues-api-version` | `ISSUES_API_VERSION` |
| `wikis-deployment-name` | `WIKIS_DEPLOYMENT_NAME` |
| `wikis-api-key` | `WIKIS_API_KEY` |
| `wikis-base-url` | `WIKIS_BASE_URL` |
| `wikis-api-version` | `WIKIS_API_VERSION` |
| `reviewer-deployment-name` | `REVIEWER_DEPLOYMENT_NAME` |
| `reviewer-api-key` | `REVIEWER_API_KEY` |
| `reviewer-base-url` | `REVIEWER_BASE_URL` |
| `reviewer-api-version` | `REVIEWER_API_VERSION` |

The Terraform infrastructure (`iac/TF/main.tf`) automatically provisions these Key Vault secrets from the deployed Azure OpenAI resource.

## Authentication

All API routes are protected by the `X-API-Key` header. The `check_apikey()` dependency splits `API_KEYS` by comma and validates the header value against the list.

```bash
# Valid request
curl -H "X-API-Key: my-local-key" http://localhost:8000/ask ...

# Returns 401
curl -H "X-API-Key: wrong-key" http://localhost:8000/ask ...
```

> **Note:** The `/docs` and `/openapi.json` GET endpoints bypass route-level auth (they are registered directly on the app, not the router).

## Timeouts & Performance

- SK agents can iterate up to **10 cycles** (termination strategy limit).
- Limit wiki and image sources to reduce token usage and response time.
- Each agent response includes `prompt_tokens` and `completion_tokens` for cost tracking.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `OSError: Missing required secrets` | Variable missing in `.env` | Check startup logs for the list of missing variable names |
| 401 on all endpoints | Invalid `X-API-Key` header | Verify your key matches one of the comma-separated values in `API_KEYS` |
| 404 from Azure OpenAI | `*_BASE_URL` contains the full deployment path | Use only the resource endpoint: `https://xxx.openai.azure.com/` |
| Issues not created | GitHub token lacks permissions | Ensure `GH_TOKEN` has `repo` scope (private repos) or `public_repo` |
| Empty exceptions list | Workspace has no recent data | Increase `days` or verify the `AppExceptions` table has data |
| `JSONDecodeError` on GET `/docs` | Outdated `InsightsMiddleware` | Ensure the middleware only parses body for POST/PUT/PATCH requests |
| Key Vault access denied in prod | Managed identity lacks RBAC role | Assign the Web App's identity the **Key Vault Secrets User** role |
