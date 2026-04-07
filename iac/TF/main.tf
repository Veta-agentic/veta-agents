###############################################################################
# Azure Verified Modules (AVM) Infrastructure
# =============================================================================
# Resources: Resource Group, Key Vault, App Service Plan, Web App,
#            Log Analytics, Application Insights, Cognitive Services (OpenAI),
#            Storage Account, Container Registry
# Authors:   Jordi Suñé, Jose Corral, David Rodriguez
###############################################################################

# ── Random suffix for globally unique names ─────────────────────────────────
resource "random_integer" "ri" {
  min = 100
  max = 999
}

# ── Data sources ────────────────────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# ── Resource Group (no AVM module available) ────────────────────────────────
resource "azurerm_resource_group" "this" {
  name     = local.resource_names.resource_group
  location = var.location
  tags     = local.common_tags
}

###############################################################################
# Monitoring
###############################################################################

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = local.resource_names.log_analytics
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = false
  tags                = local.common_tags
}

module "app_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "0.3.0"

  name                = local.resource_names.app_insights
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.log_analytics.resource_id
  application_type    = "web"
  enable_telemetry    = false
  tags                = local.common_tags
}

###############################################################################
# Cognitive Services / Azure OpenAI
###############################################################################

module "cognitive_account" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.0"

  name                          = local.resource_names.cognitive_account
  location                      = var.openai_location
  parent_id                     = azurerm_resource_group.this.id
  kind                          = "OpenAI"
  sku_name                      = "S0"
  public_network_access_enabled = var.enable_private_endpoints ? false : true

  cognitive_deployments = {
    gpt4o = {
      name = local.gpt4o_deployment_name
      model = {
        format  = "OpenAI"
        name    = "gpt-4o"
        version = var.gpt_model_version
      }
      scale = {
        type = "GlobalStandard"
      }
    }
    embedding = {
      name = local.embedding_deployment_name
      model = {
        format  = "OpenAI"
        name    = "text-embedding-3-small"
        version = var.embedding_model_version
      }
      scale = {
        type = "Standard"
      }
    }
  }

  enable_telemetry = false
  tags             = local.common_tags
}

###############################################################################
# Storage
###############################################################################

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.8"

  name                            = local.resource_names.storage_account
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  shared_access_key_enabled       = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = var.enable_private_endpoints ? false : true
  https_traffic_only_enabled      = true
  enable_telemetry                = false
  tags                            = local.common_tags
}

###############################################################################
# Container Registry
###############################################################################

module "container_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.5.1"

  name                          = local.resource_names.container_registry
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  sku                           = local.effective_acr_sku
  admin_enabled                 = var.acr_admin_enabled
  public_network_access_enabled = var.enable_private_endpoints ? false : true
  zone_redundancy_enabled       = false
  enable_telemetry              = false
  tags                          = local.common_tags
}

###############################################################################
# Key Vault (RBAC mode — AVM default)
###############################################################################

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = local.resource_names.key_vault
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_telemetry = false
  tags             = local.common_tags

  # Allow Azure services and deployer access; deny public when PE enabled
  network_acls = {
    bypass         = "AzureServices"
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
  }

  # Grant deployer permission to manage secrets during apply
  role_assignments = {
    deployer_secrets_officer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  # Agent secrets — generated via DRY locals
  secrets       = local.kv_secrets_metadata
  secrets_value = local.kv_secrets_values
}

###############################################################################
# App Service Plan
###############################################################################

module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "2.0.2"

  name                   = local.resource_names.app_service_plan
  location               = azurerm_resource_group.this.location
  os_type                = "Linux"
  parent_id              = azurerm_resource_group.this.id
  sku_name               = var.app_service_sku
  zone_balancing_enabled = can(regex("^(P|EP)", var.app_service_sku)) ? true : false
  enable_telemetry       = false
  tags                   = local.common_tags
}

###############################################################################
# Web App for Containers
###############################################################################

module "web_app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.21.8"

  name                     = local.resource_names.web_app
  location                 = azurerm_resource_group.this.location
  kind                     = "webapp"
  os_type                  = "Linux"
  parent_id                = azurerm_resource_group.this.id
  service_plan_resource_id = module.app_service_plan.resource_id
  https_only               = true
  enable_telemetry         = false
  tags                     = local.common_tags

  virtual_network_subnet_id = var.enable_private_endpoints ? azurerm_subnet.webapp[0].id : null

  managed_identities = {
    system_assigned = true
  }

  site_config = {
    always_on = true
  }

  # Application Insights connection via dedicated module inputs
  application_insights_connection_string = module.app_insights.connection_string
  application_insights_key               = module.app_insights.instrumentation_key

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "KEYVAULT_URI"                        = module.key_vault.uri
    "KEYVAULT_NAME"                       = module.key_vault.name
  }
}

###############################################################################
# RBAC — Web App Managed Identity Permissions
###############################################################################

# Key Vault Secrets User — allows the web app to read secrets
resource "azurerm_role_assignment" "webapp_kv_secrets_user" {
  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.web_app.system_assigned_mi_principal_id
}

# ACR Pull — allows the web app to pull container images
resource "azurerm_role_assignment" "webapp_acr_pull" {
  scope                = module.container_registry.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.web_app.system_assigned_mi_principal_id
}

# Storage Blob Data Contributor — allows the web app to read/write blobs
resource "azurerm_role_assignment" "webapp_storage_contributor" {
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.web_app.system_assigned_mi_principal_id
}
