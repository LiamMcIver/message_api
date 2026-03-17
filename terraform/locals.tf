locals {
  prefix = "${var.project}-${var.environment}"

  # Resource names
  resource_group_name = "${local.prefix}-rg"
  vnet_name           = "${local.prefix}-vnet"
  kv_name             = "${local.prefix}-akv"
  law_name            = "${local.prefix}-law"
  app_insights_name   = "${local.prefix}-ai"
  function_name       = "${local.prefix}-func"
  service_plan_name   = "${local.prefix}-asp"
  alert_name          = "${local.prefix}-alert-execution"
  action_group_name   = "${local.prefix}-ag"

  # Storage accounts: lowercase, no hyphens, max 24 chars
  storage_account_name = "${replace(local.prefix, "-", "")}sa"

  # Subnet names
  subnet_function_integration_name = "${local.prefix}-snet-func-int"
  subnet_private_endpoints_name    = "${local.prefix}-snet-pe"

  # NSG names
  nsg_function_integration_name = "${local.prefix}-nsg-func-int"
  nsg_private_endpoints_name    = "${local.prefix}-nsg-pe"

  # Private DNS zone names
  dns_zone_keyvault = "privatelink.vaultcore.azure.net"
  dns_zone_blob     = "privatelink.blob.core.windows.net"
  dns_zone_sites    = "privatelink.azurewebsites.net"

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}
