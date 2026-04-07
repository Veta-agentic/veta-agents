# Decisions

## 2026-04-07: OIDC Authentication for Azure Login
**By:** Morpheus
**What:** azure/login@v2 auto-detects OIDC when client-id + tenant-id provided without client-secret. Do NOT set auth-type: OIDC.
**Why:** auth-type only accepts SERVICE_PRINCIPAL and IDENTITY. OIDC is inferred.

## 2026-04-07: Federated Identity Credential Subjects
**By:** Morpheus
**What:** When GitHub Actions uses `environment: production`, the OIDC subject claim is `repo:org/repo:environment:production`, NOT `ref:refs/heads/main`.
**Why:** Subject mismatch caused deploy failures until the correct federated credential was added.

## 2026-04-07: AzureChatCompletion endpoint parameter
**By:** Trinity
**What:** Always use `endpoint=` (not `base_url=`) for AzureChatCompletion constructor.
**Why:** `base_url=` bypasses URL auto-construction, causing 404 errors on OpenAI API calls.

## 2026-04-07: Terraform AVM Modules
**By:** Morpheus
**What:** All Azure resources use AVM (Azure Verified Modules). zone_balancing is conditional, shared_access_key_enabled=false for storage.
**Why:** Best practices for production Azure infrastructure.
