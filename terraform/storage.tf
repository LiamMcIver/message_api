resource "azurerm_storage_account" "function_app" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.function_integration.id]
  }
}

# ─── Storage Container (required by Flex Consumption)

resource "azurerm_storage_container" "function_deployment" {
  name                  = "deployment-package"
  storage_account_id    = azurerm_storage_account.function_app.id
  container_access_type = "private"
}

# ─── Private Endpoint

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${local.storage_account_name}-blob-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.function_app.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
