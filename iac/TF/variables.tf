###############################################################################
# Required Variables
###############################################################################

variable "subscription_id" {
  description = "The Azure subscription ID to deploy resources into."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$", var.subscription_id))
    error_message = "The subscription ID must be a valid GUID."
  }
}

###############################################################################
# Project Configuration
###############################################################################

variable "project_name" {
  description = "Short project name used in resource naming (lowercase, no special chars)."
  type        = string
  default     = "ghbot"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project_name))
    error_message = "Project name must be 2-10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Primary Azure region for resource deployment."
  type        = string
  default     = "westus2"
}

variable "openai_location" {
  description = "Azure region for OpenAI/Cognitive Services (model availability varies by region)."
  type        = string
  default     = "eastus"
}

###############################################################################
# SKU / Sizing
###############################################################################

variable "app_service_sku" {
  description = "SKU for the App Service Plan."
  type        = string
  default     = "P0v3"

  validation {
    condition = can(regex(
      "^(B1|B2|B3|F1|D1|S1|S2|S3|P0v3|P1v2|P1v3|P2v2|P2v3|P3v2|P3v3|EP1|EP2|EP3|Y1)$",
      var.app_service_sku
    ))
    error_message = "Invalid App Service Plan SKU."
  }
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "acr_admin_enabled" {
  description = "Enable admin user on ACR. Should be false in production — use managed identity instead."
  type        = bool
  default     = false
}

###############################################################################
# OpenAI Configuration
###############################################################################

variable "openai_api_version" {
  description = "Azure OpenAI API version string."
  type        = string
  default     = "2025-01-01-preview"
}

variable "gpt_model_version" {
  description = "Version of the GPT-4o model to deploy."
  type        = string
  default     = "2024-11-20"
}

variable "embedding_model_version" {
  description = "Version of the text-embedding-3-small model to deploy."
  type        = string
  default     = "1"
}

###############################################################################
# Optional — Legacy Secrets Import
###############################################################################

variable "key_vault_secrets" {
  description = "JSON string containing key vault secrets (legacy — prefer managed identity)."
  type        = string
  default     = "{}"
  sensitive   = true
}

###############################################################################
# Networking / Private Endpoints
###############################################################################

variable "enable_private_endpoints" {
  description = "When true, deploys a VNet with private endpoints for Key Vault, Storage, ACR, Cognitive Services, and restricts Web App access via VNet integration."
  type        = bool
  default     = false
}

###############################################################################
# Tags
###############################################################################

variable "extra_tags" {
  description = "Additional tags to merge with the default tags."
  type        = map(string)
  default     = {}
}