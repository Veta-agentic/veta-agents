# Decision: Private Endpoints Toggle for Azure Infrastructure

**Date:** 2025-07-25
**By:** Morpheus
**Requested by:** Jordi Sune

## What
Added `var.enable_private_endpoints` (bool, default `false`) that conditionally deploys a VNet with private endpoints for Key Vault, Storage, ACR, and Cognitive Services. When enabled, the Web App gets VNet integration and all service network ACLs are tightened to deny public access.

## Why
Production workloads need network isolation. The toggle lets dev stay public (fast iteration) while prod can flip to private networking when ready — zero breaking changes to existing deployments.

## Files Changed
- `iac/TF/variables.tf` — new `enable_private_endpoints` variable
- `iac/TF/locals.tf` — added VNet/subnet naming, `effective_acr_sku` local
- `iac/TF/main.tf` — conditional network ACLs on KV/Storage/ACR/OpenAI, ACR SKU override, webapp VNet integration
- `iac/TF/private_endpoints.tf` — **NEW** — VNet, subnets, 4 private DNS zones, 4 VNet links, 4 private endpoints with DNS zone groups
- `iac/TF/outputs.tf` — conditional `vnet_id` and `private_endpoint_ids` outputs
- `iac/TF/terraform.dev.tfvars` — `enable_private_endpoints = false`
- `iac/TF/terraform.prod.tfvars` — `enable_private_endpoints = false` (flip when ready)
- `iac/TF/terraform.tfvars.example` — documented the flag
- `iac/TF/versions.tf` — **REMOVED** (duplicate of `providers.tf`; features merged)
- `iac/TF/providers.tf` — merged key_vault/resource_group features from versions.tf

## Validation
- `terraform fmt -recursive` ✅
- `terraform init -backend=false` ✅
- `terraform validate` ✅
