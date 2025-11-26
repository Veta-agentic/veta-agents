########################################################################################
# Terraform configuration file to create Azure resources for GitHub Bot                #
# This file creates the following resources:                                           #
# - Resource Group                                                                     #
# - Azure Key Vault                                                                    #
# - Linux App Service Plan                                                             #
# - Azure Web App for Containers                                                       #
# - Log Analytics Workspace                                                            #
# - Application Insights                                                               #
# - Azure Cognitive Services                                                           #
# - Cognitive Services Deployment (GPT-4o)                                             #
# - Cognitive Services Deployment (text-embedding)                                     #
# - Azure Storage Account                                                              #
# - Azure Container Registry                                                           #
# #################################################################################### #
# @Authors: Jordi Suñé, Jose Corral, David Rodriguez                                   #
########################################################################################

# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

#todo: add subscription_id to repo variable
provider "azurerm" {
  features {}
  subscription_id = "70ddaccd-3c7c-43bd-86bd-a6c62556c8e0"
}

# Generate a random integer to create a globally unique name
resource "random_integer" "ri" {
  min = 100
  max = 999
}

# Create the resource group
#todo: same location should be used by all resources
resource "azurerm_resource_group" "rg" {
  name     = "RSG-GHBot-${random_integer.ri.result}"
  location = "westus2"
}

# Retrieve the tenant ID dynamically
data "azurerm_client_config" "tenant" {}

# Create Azure Key Vault
resource "azurerm_key_vault" "GHBotkv" {
  name                = "keyvault-GHBot-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.tenant.tenant_id
}

# uncomment if you want to use local variables from terraform.tfvars

# locals {
#   key_vault_secrets_map = jsondecode(var.key_vault_secrets)
# }

# resource "azurerm_key_vault_secret" "secrets" {
#   for_each     = nonsensitive(local.key_vault_secrets_map)
#   name         = replace(each.key, "_", "-") # Convert underscores to dashes
#   value        = each.value
#   key_vault_id = azurerm_key_vault.GHBotkv.id
# }

# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  name                = "webapp-asp-GHBot-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P0v3"
}

# Create the Azure Web App for Containers using azurerm_linux_web_app
resource "azurerm_linux_web_app" "dockerapp" {
  name                = "webapp-GHBot-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appserviceplan.id

  site_config {
    always_on = true
  }
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.GHBot.instrumentation_key
    "KEYVAULT_URI"                        = azurerm_key_vault.GHBotkv.vault_uri
    "KEYVAULT_NAME"                      = azurerm_key_vault.GHBotkv.name
    "APPINSIGHTS__CONNECTION_STRING"      = azurerm_application_insights.GHBot.connection_string
  }
  identity {
    type = "SystemAssigned"
  }
}

#create log analytics workspace
resource "azurerm_log_analytics_workspace" "GHBot" {
  name                = "loganalytics-GHBot-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}

# Create Application Insights
resource "azurerm_application_insights" "GHBot" {
  name                = "appinsights-GHBot-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id = azurerm_log_analytics_workspace.GHBot.id
}

#Create Azure Cognitive Services
resource "azurerm_cognitive_account" "GHBot" {
  name                = "cognitive-account-GHBot-${random_integer.ri.result}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"
}

#Create Cognitive Services Deployment GPT-4o
resource "azurerm_cognitive_deployment" "GHBot" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.GHBot.id
  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-11-20"
  }
  sku {
    name = "GlobalStandard"
  }
}

# Create Cognitive Services Deployment text-embedding
resource "azurerm_cognitive_deployment" "GHBot2" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = azurerm_cognitive_account.GHBot.id
  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }
  sku {
    name = "Standard"
  }
}

# Create Azure Storage Account
resource "azurerm_storage_account" "GHBot" {
  name                     = "storageaccountghbot${random_integer.ri.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


  # Ensure that Azure AD authentication is enabled
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
}

#Create Azure Container Registry
resource "azurerm_container_registry" "GHBot" {
  name                     = "containerregistryGHBot${random_integer.ri.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = true
}

# Store cognitive services deployment secrets in Key Vault
resource "azurerm_key_vault_secret" "images_deployment" {
  name         = "images-deployment-name"
  value        = azurerm_cognitive_deployment.GHBot.name
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "images_api_key" {
  name         = "images-api-key"
  value        = azurerm_cognitive_account.GHBot.primary_access_key
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "images_base_url" {
  name         = "images-base-url"
  value        = "${azurerm_cognitive_account.GHBot.endpoint}openai/deployments/${azurerm_cognitive_deployment.GHBot.name}/chat/completions?api-version=2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "images_api_version" {
  name         = "images-api-version"
  value        = "2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "issues_deployment" {
  name         = "issues-deployment-name"
  value        = azurerm_cognitive_deployment.GHBot2.name
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "issues_api_key" {
  name         = "issues-api-key"
  value        = azurerm_cognitive_account.GHBot.primary_access_key
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "issues_base_url" {
  name         = "issues-base-url"
  value        = "${azurerm_cognitive_account.GHBot.endpoint}openai/deployments/${azurerm_cognitive_deployment.GHBot.name}/chat/completions?api-version=2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "issues_api_version" {
  name         = "issues-api-version"
  value        = "2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "wikis_deployment" {
  name         = "wikis-deployment-name"
  value        = azurerm_cognitive_deployment.GHBot.name
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "wikis_api_key" {
  name         = "wikis-api-key"
  value        = azurerm_cognitive_account.GHBot.primary_access_key
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "wikis_base_url" {
  name         = "wikis-base-url"
  value        = "${azurerm_cognitive_account.GHBot.endpoint}openai/deployments/${azurerm_cognitive_deployment.GHBot.name}/chat/completions?api-version=2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "wikis_api_version" {
  name         = "wikis-api-version"
  value        = "2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "reviewer_deployment" {
  name         = "reviewer-deployment-name"
  value        = azurerm_cognitive_deployment.GHBot2.name
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "reviewer_api_key" {
  name         = "reviewer-api-key"
  value        = azurerm_cognitive_account.GHBot.primary_access_key
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "reviewer_base_url" {
  name         = "reviewer-base-url"
  value        = "${azurerm_cognitive_account.GHBot.endpoint}openai/deployments/${azurerm_cognitive_deployment.GHBot.name}/chat/completions?api-version=2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

resource "azurerm_key_vault_secret" "reviewer_api_version" {
  name         = "reviewer-api-version"
  value        = "2025-01-01-preview"
  key_vault_id = azurerm_key_vault.GHBotkv.id
}

## Assign roles to the Web App managed identity

# Get the system-assigned identity of the Web App
data "azurerm_linux_web_app" "dockerapp" {
  name                = azurerm_linux_web_app.dockerapp.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Assign AcrPull role to the Web App managed identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.GHBot.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.dockerapp.identity[0].principal_id
}

# Assign key vault secrets key officer permissions to the Web App managed identity
resource "azurerm_key_vault_access_policy" "GHBot" {
  key_vault_id = azurerm_key_vault.GHBotkv.id
  tenant_id    = data.azurerm_client_config.tenant.tenant_id

  # The object_id of the Web App managed identity
  object_id = data.azurerm_linux_web_app.dockerapp.identity[0].principal_id
  secret_permissions = [
    "Get",
    "List"
  ]
}

# Assign Storage Blob Data Contributor role to the Web App managed identity
resource "azurerm_role_assignment" "storage_access" {
  scope                = azurerm_storage_account.GHBot.id
  role_definition_name = "Storage Blob Data Contributor" # Or adjust as needed
  principal_id         = azurerm_linux_web_app.dockerapp.identity[0].principal_id
}

