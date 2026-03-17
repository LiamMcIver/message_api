resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

# ─── Action Group ─────────────────────────────────────────────────────────────

resource "azurerm_monitor_action_group" "this" {
  name                = local.action_group_name
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "platform"
  tags                = local.tags

  email_receiver {
    name          = "platform-alerts"
    email_address = var.alert_email
  }
}

# ─── Alert Rule — HTTP 5xx errors on the Function App ────────────────────────

resource "azurerm_monitor_metric_alert" "function_5xx" {
  name                = local.alert_name
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_function_app_flex_consumption.this.id]
  description         = "Alert when Function App returns HTTP 5xx errors"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}
