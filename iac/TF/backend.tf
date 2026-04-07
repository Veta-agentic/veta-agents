# backend.tf - Remote state configuration
# Store Terraform state in Azure Storage for team collaboration

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"  # Must be globally unique - update this!
    container_name       = "tfstate"
    key                  = "veta-agents.terraform.tfstate"
    use_azuread_auth     = true
  }
}

# Note: Before running terraform init:
# 1. Create the storage account and container manually (see SETUP.md)
# 2. Update storage_account_name above with your unique name
# 3. Ensure you have access to the storage account
