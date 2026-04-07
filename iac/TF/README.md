# Veta Agents - Terraform Infrastructure

This directory contains Terraform configuration for deploying the Veta Agents infrastructure on Azure.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions

## Infrastructure Components

This Terraform configuration deploys:

- **Resource Group** - Container for all resources
- **Azure Key Vault** - Secure storage for secrets and keys
- **App Service Plan** - Linux-based hosting plan
- **Web App for Containers** - Container-based web application
- **Log Analytics Workspace** - Centralized logging
- **Application Insights** - Application monitoring
- **Azure OpenAI** - Cognitive services with GPT-4o and embeddings
- **Storage Account** - Blob storage for data
- **Container Registry** - Private container image registry

## Quick Start

### 1. Initial Setup

`ash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create remote state storage (one-time setup)
az group create --name terraform-state-rg --location westus2
az storage account create --name tfstate<unique> --resource-group terraform-state-rg --location westus2 --sku Standard_LRS
az storage container create --name tfstate --account-name tfstate<unique>
`

### 2. Configure Variables

`ash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Update subscription_id, environment, and other variables
`

### 3. Deploy Infrastructure

`ash
# Using Makefile (recommended)
make init
make plan
make apply

# Or using Terraform directly
terraform init
terraform plan -out=tfplan
terraform apply tfplan
`

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| subscription_id | Azure subscription ID | "00000000-0000-0000-0000-000000000000" |
| nvironment | Environment name | "dev", "staging", "prod" |
| project_name | Project name for resources | "GHBot" |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| location | Primary Azure region | "westus2" |
| cognitive_location | Azure OpenAI region | "eastus" |
| pp_service_sku | App Service SKU | "P0v3" |
| owner | Resource owner email | "team@example.com" |
| cost_center | Cost center for billing | "engineering" |

See [terraform.tfvars.example](terraform.tfvars.example) for all available variables.

## Remote State

This configuration uses Azure Storage for remote state management:

- **Resource Group**: 	erraform-state-rg
- **Storage Account**: 	fstate<unique> (must be globally unique)
- **Container**: 	fstate
- **State File**: eta-agents.terraform.tfstate

Update [backend.tf](backend.tf) with your storage account name before running 	erraform init.

## Makefile Commands

`ash
make help      # Show available commands
make init      # Initialize Terraform
make validate  # Validate configuration
make fmt       # Format Terraform files
make plan      # Generate execution plan
make apply     # Apply changes
make destroy   # Destroy infrastructure
make output    # Show output values
make clean     # Clean local cache
`

## Outputs

After successful deployment, Terraform outputs:

- Resource Group name and location
- Key Vault name and URI
- Web App name and hostname
- Container Registry login server
- Storage Account details
- Cognitive Services endpoints
- Application Insights connection strings

View outputs:

`ash
terraform output
# or
make output
`

## Multi-Environment Strategy

This configuration supports multiple environments through workspaces:

`ash
# Create and select workspace
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Select workspace
terraform workspace select dev

# Apply configuration
terraform apply
`

## Security Best Practices

✅ **Implemented:**
- Managed identities for authentication
- Key Vault for secrets management
- RBAC role assignments
- Private network access where applicable
- Encrypted storage at rest
- Application Insights for monitoring

⚠️ **Recommendations:**
- Enable Azure AD authentication for Container Registry
- Configure network security groups
- Enable advanced threat protection
- Set up diagnostic settings for all resources
- Implement backup policies for Key Vault and Storage

## Cost Optimization

Current SKU selections:
- **App Service Plan**: P0v3 (Premium v3)
- **Container Registry**: Basic
- **Storage**: Standard LRS
- **OpenAI**: S0 with Global Standard deployment

To reduce costs in dev/test:
- Use B-series SKUs for App Service
- Consider consumption-based alternatives
- Review OpenAI model versions and capacity

## Troubleshooting

### Issue: Backend initialization fails

**Solution**: Ensure the storage account exists and you have access:

`ash
az storage account show --name tfstate<unique> --resource-group terraform-state-rg
`

### Issue: Key Vault access denied

**Solution**: Grant yourself access policies:

`ash
# Get your object ID
az ad signed-in-user show --query id -o tsv

# Set Key Vault access policy
az keyvault set-policy --name <keyvault-name> --object-id <your-object-id> --secret-permissions get list set
`

### Issue: Cognitive Services quota exceeded

**Solution**: Check quotas and request increases:

`ash
az cognitiveservices account list-skus --resource-group <rg-name> --name <account-name>
`

## Maintenance

### Drift Detection

Check for configuration drift:

`ash
terraform plan -detailed-exitcode
`

### Import Existing Resources

To import manually created resources:

`ash
terraform import azurerm_resource_group.rg /subscriptions/{subscription-id}/resourceGroups/{rg-name}
`

### State Management

`ash
# List resources in state
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.rg

# Remove resource from state
terraform state rm azurerm_resource_group.rg
`

## Contributing

Before committing changes:

`ash
# Run pre-commit checks
make pre-commit

# Or manually
terraform fmt -recursive
terraform validate
`

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure OpenAI Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## Support

For issues or questions:
- Open an issue in the repository
- Contact the DevOps team
- Review Azure documentation
