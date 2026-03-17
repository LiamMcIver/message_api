# ─── Virtual Network

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

# ─── Subnets

resource "azurerm_subnet" "function_integration" {
  name                 = local.subnet_function_integration_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_function_integration_cidr]

  delegation {
    name = "function-app-delegation"
    service_delegation {
      name    = "Microsoft.Web/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = local.subnet_private_endpoints_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_private_endpoints_cidr]

  private_endpoint_network_policies = "Disabled"
}

# ─── Network Security Groups 

resource "azurerm_network_security_group" "function_integration" {
  name                = local.nsg_function_integration_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  # Allow outbound to private endpoints subnet (Key Vault, Storage)
  security_rule {
    name                       = "AllowOutboundToPrivateEndpoints"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_function_integration_cidr
    destination_address_prefix = var.subnet_private_endpoints_cidr
  }

  # Allow outbound to Azure Monitor / App Insights
  security_rule {
    name                       = "AllowOutboundAzureMonitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_function_integration_cidr
    destination_address_prefix = "AzureMonitor"
  }

  # Deny all other outbound
  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "private_endpoints" {
  name                = local.nsg_private_endpoints_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  # Allow inbound HTTPS from function integration subnet only
  security_rule {
    name                       = "AllowInboundFromFunctionSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_function_integration_cidr
    destination_address_prefix = var.subnet_private_endpoints_cidr
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ─── NSG Associations

resource "azurerm_subnet_network_security_group_association" "function_integration" {
  subnet_id                 = azurerm_subnet.function_integration.id
  network_security_group_id = azurerm_network_security_group.function_integration.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

# ─── Private DNS Zones

resource "azurerm_private_dns_zone" "keyvault" {
  name                = local.dns_zone_keyvault
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "blob" {
  name                = local.dns_zone_blob
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "sites" {
  name                = local.dns_zone_sites
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# ─── DNS Zone VNet Links

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "${local.prefix}-kv-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "${local.prefix}-blob-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sites" {
  name                  = "${local.prefix}-sites-dns-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.sites.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}
