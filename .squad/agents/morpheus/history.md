# Morpheus — History

## Core Context
- Project: GitHub AI Bot (veta-agents) — Python/FastAPI + Azure OpenAI agents
- User: Jordi Sune
- Stack: Python 3.12, FastAPI, Terraform (AVM), Docker, GitHub Actions, Azure (westeurope)
- Infra: rsg-ghbot-854, app-ghbot-854, crghbot854, oai-ghbot-854, kv-ghbot-854, law-ghbot-854
- OIDC App: github-veta-agents (f65b2059-5e5a-47ab-baed-2f3851f7f8ab)

## Learnings
- 2026-04-07: `azure/login@v2` does NOT accept `auth-type: OIDC` — OIDC is auto-detected when client-id + tenant-id are provided without client-secret
- 2026-04-07: When workflow uses `environment: production`, OIDC subject is `repo:org/repo:environment:production` not `ref:refs/heads/main`
- 2026-04-07: Three federated creds exist: github-actions-main, github-actions-pr, github-env-production
- 2026-04-07: IaC uses AVM modules, zone_balancing conditional, shared_access_key_enabled=false for storage
- 2026-04-07: deploy-all.ps1 requires pwsh (PS7), uses temp file JSON for federated creds
