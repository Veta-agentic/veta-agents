###############################################################################
# Naming Conventions & Shared Values
###############################################################################

locals {
  suffix = random_integer.ri.result

  # Azure CAF-aligned naming convention
  resource_names = {
    resource_group     = "rsg-${var.project_name}-${local.suffix}"
    key_vault          = "kv-${var.project_name}-${local.suffix}"
    app_service_plan   = "asp-${var.project_name}-${local.suffix}"
    web_app            = "app-${var.project_name}-${local.suffix}"
    log_analytics      = "law-${var.project_name}-${local.suffix}"
    app_insights       = "appi-${var.project_name}-${local.suffix}"
    cognitive_account  = "oai-${var.project_name}-${local.suffix}"
    storage_account    = "st${var.project_name}${local.suffix}"
    container_registry = "cr${var.project_name}${local.suffix}"
  }

  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.extra_tags)

  # ── OpenAI deployment names (single source of truth) ──────────────────────
  gpt4o_deployment_name     = "gpt-4o"
  embedding_deployment_name = "text-embedding-3-small"

  # ── Agent → deployment mapping (DRY secrets) ──────────────────────────────
  agents = ["images", "issues", "wikis", "reviewer"]

  agent_deployment_map = {
    images   = local.gpt4o_deployment_name
    issues   = local.embedding_deployment_name
    wikis    = local.gpt4o_deployment_name
    reviewer = local.embedding_deployment_name
  }

  # Key Vault secret metadata (non-sensitive, safe for for_each)
  kv_secrets_metadata = merge([
    for agent in local.agents : {
      "${agent}-deployment-name" = { name = "${agent}-deployment-name" }
      "${agent}-api-key"         = { name = "${agent}-api-key" }
      "${agent}-base-url"        = { name = "${agent}-base-url" }
      "${agent}-api-version"     = { name = "${agent}-api-version" }
    }
  ]...)

  # Key Vault secret values (sensitive — passed via secrets_value)
  kv_secrets_values = merge([
    for agent in local.agents : {
      "${agent}-deployment-name" = local.agent_deployment_map[agent]
      "${agent}-api-key"         = module.cognitive_account.primary_access_key
      "${agent}-base-url"        = "${module.cognitive_account.endpoint}openai/deployments/${local.gpt4o_deployment_name}/chat/completions?api-version=${var.openai_api_version}"
      "${agent}-api-version"     = var.openai_api_version
    }
  ]...)
}
