# Orchestration: Morpheus (env-tfvars)

**Agent:** Morpheus  
**Task:** Update deploy scripts for branch→env tfvars routing  
**Branch:** `feature/iac-avm-modules`  
**Status:** COMPLETED  
**Timestamp:** 2026-04-07T11:15:45Z  

## Summary
Implemented environment-specific Terraform variable files with automatic branch-based routing. Main branch deployments use production tfvars; all other branches use development tfvars. Removed generic terraform.tfvars.example in favor of explicit environment files.

## Deliverables
- **terraform.prod.tfvars**: Production resource group and subscription configuration
- **terraform.dev.tfvars**: Development resource group and subscription configuration
- **Updated deploy-infra.ps1**: Auto-selects tfvars based on current git branch

## Results
- ✓ terraform.prod.tfvars created with prod settings
- ✓ terraform.dev.tfvars created with dev settings
- ✓ deploy-infra.ps1 updated with branch detection logic
- ✓ terraform.tfvars.example removed
- ✓ Committed SHA 36c940f

## Configuration Details
- **Prod**: RSG for production deployments (branch: main)
- **Dev**: RSG for development/feature deployments (branch: other)
- **Automatic routing**: Script detects current branch and applies correct tfvars

## Team Impact
Enforces environment isolation and prevents accidental production deployments from feature branches. Simplifies CI/CD configuration by eliminating manual env selection.
