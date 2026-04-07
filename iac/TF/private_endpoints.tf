###############################################################################
# Private Endpoints & Networking
# =============================================================================
# All resources conditional on var.enable_private_endpoints.
# When false (default), nothing here is created — public access preserved.
###############################################################################

# ── Virtual Network ─────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "this" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = local.resource_names.vnet
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.common_tags
}

# ── Subnets ─────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "pe" {
  count                = var.enable_private_endpoints ? 1 : 0
  name                 = local.resource_names.snet_pe
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "webapp" {
  count                = var.enable_private_endpoints ? 1 : 0
  name                 = local.resource_names.snet_webapp
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# ── Private DNS Zones ───────────────────────────────────────────────────────

resource "azurerm_private_dns_zone" "keyvault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "acr" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "openai" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# ── Private DNS Zone → VNet Links ───────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdnslink-keyvault"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdnslink-blob"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdnslink-acr"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  count                 = var.enable_private_endpoints ? 1 : 0
  name                  = "pdnslink-openai"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.openai[0].name
  virtual_network_id    = azurerm_virtual_network.this[0].id
  registration_enabled  = false
  tags                  = local.common_tags
}

# ── Private Endpoints ───────────────────────────────────────────────────────

resource "azurerm_private_endpoint" "keyvault" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${local.resource_names.key_vault}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.pe[0].id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = module.key_vault.resource_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault[0].id]
  }
}

resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${local.resource_names.storage_account}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.pe[0].id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = module.storage_account.resource_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}

resource "azurerm_private_endpoint" "acr" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${local.resource_names.container_registry}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.pe[0].id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-acr"
    private_connection_resource_id = module.container_registry.resource_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-acr"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}

resource "azurerm_private_endpoint" "openai" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "pe-${local.resource_names.cognitive_account}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.pe[0].id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-openai"
    private_connection_resource_id = module.cognitive_account.resource_id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnszg-openai"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai[0].id]
  }
}
