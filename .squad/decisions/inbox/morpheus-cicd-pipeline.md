# Decision: CI/CD Pipeline Modernization

**Date:** 2025-07-18
**Author:** Morpheus (DevOps/Infra)
**Status:** Implemented (branch `feature/iac-avm-modules`, commit `3a7ffc9`)

## Context

The existing `deploy.yml` workflow was broken after the AVM migration:
- Hardcoded old resource names (`RSG-GHBot-285`, `containerregistryGHBot285.azurecr.io`, `webapp-GHBot-285`)
- Used ACR admin username/password secrets (admin now disabled per AVM best practices)
- Only triggered on `main` push — no CI for PRs or feature branches
- No test or lint steps before deploying
- Failed on its only run (Nov 2025)

## Decision

Split into two workflows:

1. **CI (`ci.yml`)** — Runs on PRs and feature branches: lint (ruff), test (pytest), Docker build validation, Terraform validate
2. **CD (`deploy.yml`)** — Runs on `main` push only: OIDC Azure login, build+push to ACR, deploy to Web App, health check

Authentication switched from service principal secrets to OIDC federated credentials (`azure/login@v2`). All resource names are now GitHub repository Variables (not hardcoded).

## Consequences

- **Requires setup:** An Azure AD app registration with a federated credential for `repo:<owner>/veta-agents:ref:refs/heads/main` must be created. GitHub Variables (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `ACR_NAME`, `WEB_APP_NAME`, `RESOURCE_GROUP`) must be configured.
- **No more secret rotation:** OIDC tokens are short-lived and auto-managed.
- **Feature branches get CI:** Every PR and push to non-main branches runs lint + test + Docker build + Terraform validate.
- **Safer deploys:** Tests must pass before deploy; concurrency group prevents overlapping production deploys.

## Team Impact

- **Trinity (App):** No code changes needed. CI will catch lint/test failures on PRs before merge.
- **Niobe (Test):** Tests now run automatically in CI. Test failures will block merges and deploys.
- **Neo (Arch):** OIDC aligns with Zero Trust. Federated credential setup documented in `.github/workflows/README.md`.
