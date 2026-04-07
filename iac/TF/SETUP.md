# Terraform Setup Guide

This guide walks you through setting up the Terraform infrastructure for Veta Agents.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Remote State Configuration](#remote-state-configuration)
4. [Variable Configuration](#variable-configuration)
5. [Deployment](#deployment)
6. [Post-Deployment](#post-deployment)
7. [Common Issues](#common-issues)

## Prerequisites

Before you begin, ensure you have:

- **Terraform** >= 1.5.0 installed
- **Azure CLI** installed and configured
- **Make** (optional, for using Makefile commands)
- Azure subscription with Owner or Contributor role

### Install Terraform

**Windows (using Chocolatey):**
```powershell
choco install terraform
```

**macOS (using Homebrew):**
```bash
brew install terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Install Azure CLI

Follow instructions at: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

## Initial Setup

### 1. Login to Azure

```bash
az login
```

### 2. Set Your Subscription

```bash
# List available subscriptions
az account list --output table

# Set active subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

## Remote State Configuration

Terraform uses Azure Storage to store state files remotely. This enables team collaboration and state locking.

### Create Remote State Storage

Run these commands **once** to create the backend storage:

```bash
# Set variables
RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstatevetaagents"  # Must be globally unique, change if needed
CONTAINER_NAME="tfstate"
LOCATION="westus2"

# Create resource group
az group create \
  --name  \
  --location 

# Create storage account
az storage account create \
  --name  \
  --resource-group  \
  --location  \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --name  \
  --account-name  \
  --auth-mode login
```

### Update backend.tf

Edit ackend.tf and update the storage account name:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatevetaagents"  # Your storage account name
    container_name       = "tfstate"
    key                  = "veta-agents.terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

## Variable Configuration

### 1. Copy Example Variables

```bash
cd iac/TF
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

Edit 	erraform.tfvars with your values:

```hcl
# Required
subscription_id = "YOUR_SUBSCRIPTION_ID"

# Environment
environment  = "dev"
project_name = "GHBot"

# Locations
location           = "westus2"
cognitive_location = "eastus"

# Tags
owner       = "your-team@example.com"
cost_center = "engineering"
```

### 3. Protect terraform.tfvars

Add to .gitignore (already done):

```bash
echo "*.tfvars" >> .gitignore
```

## Deployment

### Using Makefile (Recommended)

```bash
# Initialize Terraform
make init

# Format code
make fmt

# Validate configuration
make validate

# Create execution plan
make plan

# Review the plan output carefully!

# Apply changes
make apply
```

### Using Terraform Commands

```bash
# Initialize
terraform init

# Format
terraform fmt -recursive

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Deployment Time

Expected deployment time: **15-20 minutes**

Resources are created in this order:
1. Resource Group
2. Key Vault (with access policies)
3. Log Analytics & App Insights
4. Storage Account
5. Container Registry
6. Cognitive Services
7. App Service Plan & Web App

## Post-Deployment

### 1. View Outputs

```bash
# View all outputs
terraform output

# or
make output

# View specific output
terraform output web_app_name
terraform output key_vault_uri
```

### 2. Verify Resources

```bash
# List resources in resource group
RESOURCE_GROUP=[33mΓò╖[0m[0m [33mΓöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mΓöé[0m [0m [33mΓöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define an output in your configuration with the `output` keyword and run `terraform [33mΓöé[0m [0mrefresh` for it to become available. If you are using interpolation, please verify the interpolated value is not empty. You can use the `terraform console` command to assist. [33mΓò╡[0m[0m
az resource list --resource-group  --output table
```

### 3. Configure Secrets

Add application secrets to Key Vault:

```bash
KEY_VAULT_NAME=[33mΓò╖[0m[0m [33mΓöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mΓöé[0m [0m [33mΓöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define an output in your configuration with the `output` keyword and run `terraform [33mΓöé[0m [0mrefresh` for it to become available. If you are using interpolation, please verify the interpolated value is not empty. You can use the `terraform console` command to assist. [33mΓò╡[0m[0m

# Example: Add GitHub token
az keyvault secret set \
  --vault-name  \
  --name "GITHUB-TOKEN" \
  --value "your-github-token"
```

### 4. Deploy Container to Web App

```bash
ACR_NAME=[33mΓò╖[0m[0m [33mΓöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mΓöé[0m [0m [33mΓöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define an output in your configuration with the `output` keyword and run `terraform [33mΓöé[0m [0mrefresh` for it to become available. If you are using interpolation, please verify the interpolated value is not empty. You can use the `terraform console` command to assist. [33mΓò╡[0m[0m
WEB_APP_NAME=[33mΓò╖[0m[0m [33mΓöé[0m [0m[1m[33mWarning: [0m[0m[1mNo outputs found[0m [33mΓöé[0m [0m [33mΓöé[0m [0m[0mThe state file either has no outputs defined, or all the defined outputs are empty. Please define an output in your configuration with the `output` keyword and run `terraform [33mΓöé[0m [0mrefresh` for it to become available. If you are using interpolation, please verify the interpolated value is not empty. You can use the `terraform console` command to assist. [33mΓò╡[0m[0m

# Configure Web App to use ACR
az webapp config container set \
  --name  \
  --resource-group  \
  --docker-custom-image-name .azurecr.io/veta-agents:latest \
  --docker-registry-server-url https://.azurecr.io
```

## Common Issues

### Issue 1: Backend initialization fails

**Error:** "storage account does not exist"

**Solution:**
```bash
# Verify storage account exists
az storage account show \
  --name tfstatevetaagents \
  --resource-group terraform-state-rg
```

### Issue 2: Permission denied

**Error:** "authorization failed" or "insufficient permissions"

**Solution:**
```bash
# Check your role assignment
az role assignment list \
  --assignee Jordi@msafaber.com \
  --output table

# You need at least "Contributor" role
```

### Issue 3: Key Vault access denied

**Error:** "The user, group or application does not have secrets get permission"

**Solution:**
```bash
# Get your object ID
OBJECT_ID=b27e0610-91f9-44b2-b06f-d8827542ddb4

# Grant access
az keyvault set-policy \
  --name YOUR_KEYVAULT_NAME \
  --object-id  \
  --secret-permissions get list set delete
```

### Issue 4: Resource name already exists

**Error:** "A resource with that name already exists"

**Solution:**
- Change project_name in 	erraform.tfvars
- Or destroy the conflicting resource
- Or import existing resource: 	erraform import <resource_type>.<name> <azure_resource_id>

### Issue 5: Cognitive Services quota exceeded

**Error:** "The subscription has exceeded quota"

**Solution:**
```bash
# Request quota increase
# Or use a different region
# Or use different model
```

## Multi-Environment Setup

### Using Workspaces

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select dev

# Deploy to specific environment
terraform apply -var="environment=dev"
```

### Using Separate Directories

```
iac/
  environments/
    dev/
      terraform.tfvars
    staging/
      terraform.tfvars
    prod/
      terraform.tfvars
```

## Cleanup

### Destroy Infrastructure

**WARNING:** This will delete all resources!

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy
terraform destroy

# or using Makefile
make destroy
```

### Remove State Files (Local Only)

```bash
make clean
```

## Next Steps

1. **Configure CI/CD**: Set up GitHub Actions or Azure DevOps pipeline
2. **Enable Monitoring**: Configure alerts in Application Insights
3. **Add Custom Domain**: Configure custom domain for Web App
4. **Enable HTTPS**: Configure SSL certificate
5. **Network Security**: Configure NSGs and private endpoints
6. **Backup Strategy**: Set up backup for Key Vault and Storage

## Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

## Getting Help

- Check [README.md](README.md) for overview
- Review Terraform documentation
- Open an issue in the repository
- Contact DevOps team
