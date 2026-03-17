output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "function_app_hostname" {
  description = "Default hostname of the Function App (private — only reachable within VNet)"
  value       = azurerm_function_app_flex_consumption.this.default_hostname
}

output "function_app_private_endpoint_ip" {
  description = "Private IP address of the Function App private endpoint"
  value       = azurerm_private_endpoint.function_app.private_service_connection[0].private_ip_address
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App system-assigned managed identity"
  value       = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.id
}
