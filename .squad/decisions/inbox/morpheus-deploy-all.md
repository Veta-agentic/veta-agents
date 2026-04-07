# Decision: End-to-End Deploy Script (deploy-all.ps1)

**Date:** 2025-07-18
**Author:** Morpheus (DevOps/Infra)
**Status:** Implemented (branch `feature/iac-avm-modules`, commit `fe52293`)

## Context

After the AVM migration and CI/CD pipeline modernization, deploying veta-agents still required multiple manual steps:
1. Run Terraform to provision infrastructure
2. Manually create an Azure AD app registration with OIDC federated credentials
3. Manually configure 7+ GitHub repository variables
4. Build and push the Docker image

Jordi (project lead) requested a single script to orchestrate all of this.

## Decision

Created `scripts/deploy-all.ps1` — a six-phase orchestrator that handles authentication, infrastructure, OIDC setup, GitHub configuration, app deployment, and a final summary. Each phase is independently skippable via `-Skip*` switches for incremental re-runs.

Key design choices:
- **Idempotent**: Every resource creation is preceded by an existence check (app registrations, federated credentials, role assignments, service principals)
- **Inline Terraform** (not delegating to `deploy-infra.ps1`): Captures `terraform output -json` into script variables for use by subsequent phases
- **OIDC federated credentials**: Two entries — `main` branch (for CD) and `pull_request` (for CI)
- **GitHub Variables via `gh` CLI**: All non-sensitive values set as variables; only `HTTP_API_KEY` flagged as a manual secret step
- **Same helper function pattern** as existing scripts (`Write-Status`, `Write-Success`, `Write-Failure`, `Write-Step`)

Also updated `terraform.dev.tfvars` and `terraform.prod.tfvars` with the real subscription ID.

## Consequences

- **Jordi** can run `.\scripts\deploy-all.ps1` to go from zero to fully deployed + GitHub-configured in one command
- **Re-runs are safe**: Skip flags allow targeting specific phases after partial failures
- **Requires**: Azure CLI, Terraform, Docker, and GitHub CLI (`gh`) installed locally
- **One manual step remains**: `HTTP_API_KEY` must be set as a GitHub Secret (the script reminds the user)

## Team Impact

- **Trinity (App):** No code changes. The app is deployed via the same Docker build process.
- **Niobe (Test):** Can use `smoke-test.ps1` after `deploy-all.ps1` to validate the deployment.
- **Neo (Arch):** OIDC + RBAC setup follows Zero Trust principles; no long-lived secrets.
