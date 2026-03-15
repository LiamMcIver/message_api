resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "EP1" # Elastic Premium required for VNet integration
  tags                = local.tags
}

resource "azurerm_linux_function_app" "this" {
  name                          = local.function_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  service_plan_id               = azurerm_service_plan.this.id
  storage_account_name          = azurerm_storage_account.function_app.name
  storage_account_access_key    = azurerm_storage_account.function_app.primary_access_key
  https_only                    = true
  virtual_network_subnet_id     = azurerm_subnet.function_integration.id
  public_network_access_enabled = false

  # mTLS — enforce client certificate at the platform level
  # Requests without a valid certificate are rejected before reaching Python
  client_certificate_enabled = true
  client_certificate_mode    = "Required"

  tags = local.tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key
    vnet_route_all_enabled                 = true

    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"                 = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING"    = azurerm_application_insights.this.connection_string
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.function_app.primary_connection_string
    "WEBSITE_CONTENTSHARE"                     = local.function_name
    "WEBSITE_RUN_FROM_PACKAGE"                 = "1"
    "WEBSITE_VNET_ROUTE_ALL"                   = "1"
    # Thumbprint of the CA cert — used by the function to validate the client cert chain
    "CLIENT_CERT_CA_THUMBPRINT" = tls_self_signed_cert.ca.cert_pem
  }
}

# ─── Private Endpoint — this is the API layer ─────────────────────────────────
# All inbound traffic must come through this private endpoint.
# The Function App has public_network_access_enabled = false so this is
# the only way to reach it.

resource "azurerm_private_endpoint" "function_app" {
  name                = "${local.function_name}-pe"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.function_name}-psc"
    private_connection_resource_id = azurerm_linux_function_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "function-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sites.id]
  }
}
