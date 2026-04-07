###############################################################################
# Outputs
###############################################################################

# ── Resource Group ──────────────────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

# ── Key Vault ───────────────────────────────────────────────────────────────
output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = module.key_vault.resource_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.key_vault.uri
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.key_vault.name
}

# ── App Service ─────────────────────────────────────────────────────────────
output "app_service_plan_id" {
  description = "Resource ID of the App Service Plan."
  value       = module.app_service_plan.resource_id
}

output "web_app_id" {
  description = "Resource ID of the Web App."
  value       = module.web_app.resource_id
  sensitive   = true
}

output "web_app_name" {
  description = "Name of the Web App."
  value       = module.web_app.name
}

output "web_app_default_hostname" {
  description = "Default hostname of the Web App."
  value       = module.web_app.resource_uri
}

output "web_app_principal_id" {
  description = "Principal ID of the Web App system-assigned managed identity."
  value       = module.web_app.system_assigned_mi_principal_id
  sensitive   = true
}

# ── Monitoring ──────────────────────────────────────────────────────────────
output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = module.log_analytics.resource_id
}

output "app_insights_id" {
  description = "Resource ID of Application Insights."
  value       = module.app_insights.resource_id
}

output "app_insights_connection_string" {
  description = "Connection string for Application Insights."
  value       = module.app_insights.connection_string
  sensitive   = true
}

output "app_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights."
  value       = module.app_insights.instrumentation_key
  sensitive   = true
}

# ── Cognitive Services / OpenAI ─────────────────────────────────────────────
output "cognitive_account_id" {
  description = "Resource ID of the Cognitive Services account."
  value       = module.cognitive_account.resource_id
}

output "cognitive_account_endpoint" {
  description = "Endpoint of the Cognitive Services account."
  value       = module.cognitive_account.endpoint
}

# ── Storage ─────────────────────────────────────────────────────────────────
output "storage_account_id" {
  description = "Resource ID of the Storage Account."
  value       = module.storage_account.resource_id
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = module.storage_account.name
}

# ── Container Registry ──────────────────────────────────────────────────────
output "container_registry_id" {
  description = "Resource ID of the Container Registry."
  value       = module.container_registry.resource_id
}

output "container_registry_name" {
  description = "Name of the Container Registry."
  value       = module.container_registry.name
}
