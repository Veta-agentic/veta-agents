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
- 2025-07-25: Added `enable_private_endpoints` toggle (default false) — VNet, private DNS zones, PEs for KV/Storage/ACR/OpenAI, webapp VNet integration, network ACL tightening. All in `private_endpoints.tf` using `count` pattern.
- 2025-07-25: ACR private endpoints require Premium SKU — use `local.effective_acr_sku` to auto-upgrade when PE enabled
- 2025-07-25: Resolved duplicate provider config: merged `versions.tf` features into `providers.tf` and deleted `versions.tf`
- 2025-07-25: AVM modules (storage v0.6.8, ACR v0.5.1, cognitive v0.11.0, web v0.21.8, keyvault v0.10.2) all accept `public_network_access_enabled` and `virtual_network_subnet_id` parameters directly
