# Configuration & Environment Variables

## Required Variables (per `Config._validate_secrets`)
| Name | Description |
|------|-------------|
| GH_TOKEN | GitHub token for issues/repos |
| IMAGES_DEPLOYMENT_NAME | Azure OpenAI images deployment name |
| IMAGES_API_KEY | API key for images model |
| IMAGES_BASE_URL | Base endpoint for images model |
| IMAGES_API_VERSION | API version for images model |
| ISSUES_DEPLOYMENT_NAME | Issues search deployment |
| ISSUES_API_KEY | Issues model API key |
| ISSUES_BASE_URL | Issues model base endpoint |
| ISSUES_API_VERSION | Issues model API version |
| WIKIS_DEPLOYMENT_NAME | Wikis retrieval deployment |
| WIKIS_API_KEY | Wikis model API key |
| WIKIS_BASE_URL | Wikis model base endpoint |
| WIKIS_API_VERSION | Wikis model API version |
| REVIEWER_DEPLOYMENT_NAME | Reviewer deployment |
| REVIEWER_API_KEY | Reviewer model API key |
| REVIEWER_BASE_URL | Reviewer model base endpoint |
| REVIEWER_API_VERSION | Reviewer model API version |

## Others
| Name | Description |
|------|-------------|
| ENVIRONMENT | `dev` uses environment variables, any other value uses KeyVault |
| KEYVAULT_NAME | Azure Key Vault name in prod |

## Example `.env`
```env
ENVIRONMENT=dev
GH_TOKEN=ghp_XXXX
IMAGES_DEPLOYMENT_NAME=images-depl
IMAGES_API_KEY=xxx
IMAGES_BASE_URL=https://YOUR.openai.azure.com/
IMAGES_API_VERSION=2024-06-01
ISSUES_DEPLOYMENT_NAME=issues-depl
ISSUES_API_KEY=xxx
ISSUES_BASE_URL=https://YOUR.openai.azure.com/
ISSUES_API_VERSION=2024-06-01
WIKIS_DEPLOYMENT_NAME=wikis-depl
WIKIS_API_KEY=xxx
WIKIS_BASE_URL=https://YOUR.openai.azure.com/
WIKIS_API_VERSION=2024-06-01
REVIEWER_DEPLOYMENT_NAME=reviewer-depl
REVIEWER_API_KEY=xxx
REVIEWER_BASE_URL=https://YOUR.openai.azure.com/
REVIEWER_API_VERSION=2024-06-01
API_KEYS=local-api-key
```

## Timeouts & Performance
- SK Agents can iterate up to 10 cycles (termination strategy limit).
- Limit wiki and image sources to reduce token usage.

## Troubleshooting
| Problem | Cause | Fix |
|---------|-------|-----|
| Missing required secrets | Variable missing in `.env` | Check logs and add missing values |
| 401 on endpoints | Invalid `X-API-Key` header | Verify `API_KEYS` in `.env` |
| Issues not created | GitHub token missing scopes | Ensure scopes: `repo` / `public_repo` |
| Empty exceptions list | Workspace has no recent data | Adjust `days` or inspect `AppExceptions` table |
