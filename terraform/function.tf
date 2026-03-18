# ─── Service Plan

resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "FC1" # Flex consumption
  tags                = local.tags
}

# ─── Function App

resource "azurerm_function_app_flex_consumption" "this" {
  name                       = local.function_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  service_plan_id            = azurerm_service_plan.this.id
  client_certificate_enabled = true
  client_certificate_mode    = "Required"


  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.function_app.primary_blob_endpoint}${azurerm_storage_container.function_deployment.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.function_app.primary_access_key

  runtime_name           = "python"
  runtime_version        = "3.11"
  maximum_instance_count = 40
  instance_memory_in_mb  = 512

  virtual_network_subnet_id = azurerm_subnet.function_integration.id

  identity {
    type = "SystemAssigned"
  }
  site_config {

  }
  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.this.connection_string
  }

  tags = local.tags
}

# ─── Private Endpoint

resource "azurerm_private_endpoint" "function_app" {
  name                = "${local.function_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.function_name}-psc"
    private_connection_resource_id = azurerm_function_app_flex_consumption.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "function-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sites.id]
  }
}