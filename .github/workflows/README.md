# GitHub Actions Workflows

## Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI** | `ci.yml` | PRs to `main`, pushes to feature branches | Lint, test, Docker build validation, Terraform validate |
| **CD** | `deploy.yml` | Push to `main` (app-related paths) | Build, push to ACR, deploy to Azure Web App |
| **Help** | `help.yml` | Issue opened with `help wanted` label | Calls the bot API and posts the answer as a comment |

## Required GitHub Configuration

### Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_CLIENT_ID` | App registration client ID (for OIDC) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure AD tenant ID | `5bd20065-3bf3-4766-a65c-efb7fe403ef7` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `0680501b-ff10-40d8-b73a-4b6fbe760883` |
| `ACR_NAME` | Azure Container Registry name (short name, not FQDN) | `crveta1a2b3c` |
| `WEB_APP_NAME` | Azure Web App name | `app-veta-1a2b3c` |
| `RESOURCE_GROUP` | Azure Resource Group name | `rsg-veta-1a2b3c` |
| `HTTP_URL` | Bot API endpoint URL (for `help.yml`) | `https://app-veta-1a2b3c.azurewebsites.net/ask` |
| `GH_WIKIS` | GitHub Wiki config JSON (for `help.yml`) | `["owner/repo"]` |
| `GH_WIKI_BASEIMAGEURL` | Base URL for wiki images | `https://...` |
| `GH_REPO` | GitHub repository reference | `owner/repo` |

### Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Description | Used by |
|--------|-------------|---------|
| `HTTP_API_KEY` | API key for the bot's `/ask` endpoint | `help.yml` |

## OIDC Authentication Setup

The CD pipeline uses **OpenID Connect (OIDC)** federated credentials instead of long-lived service principal secrets. This is more secure — no passwords to rotate.

### How it works

1. GitHub Actions requests a short-lived token from GitHub's OIDC provider
2. Azure AD validates the token against a federated credential trust policy
3. The workflow gets a temporary Azure access token (no secrets stored)

### Setup steps

1. **Create an Azure AD App Registration** (or use an existing one):
   ```bash
   az ad app create --display-name "github-veta-agents"
   ```

2. **Create a federated credential** for the `main` branch:
   ```bash
   az ad app federated-credential create --id <APP_OBJECT_ID> --parameters '{
     "name": "github-main-branch",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:<OWNER>/veta-agents:ref:refs/heads/main",
     "audiences": ["api://AzureADTokenExchange"]
   }'
   ```

3. **Create a service principal** and assign roles:
   ```bash
   az ad sp create --id <APP_CLIENT_ID>
   az role assignment create --assignee <APP_CLIENT_ID> \
     --role "Contributor" \
     --scope "/subscriptions/0680501b-ff10-40d8-b73a-4b6fbe760883"
   ```

4. **Set the GitHub variables** listed above with the app registration's client ID, tenant ID, and subscription ID.

### References

- [Azure OIDC for GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
- [Configuring OIDC in Azure](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure)
