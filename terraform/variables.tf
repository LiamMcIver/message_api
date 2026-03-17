variable "project" {
  type        = string
  description = "Project name used as a prefix for all resources"
  default     = "message-api"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region for all resources"
  default     = "uksouth"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_function_integration_cidr" {
  type        = string
  description = "CIDR for the Function App VNet integration subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_private_endpoints_cidr" {
  type        = string
  description = "CIDR for the private endpoints subnet"
  default     = "10.0.2.0/24"
}

variable "alert_email" {
  type        = string
  description = "Email address for monitoring alerts"
  default     = "platform-alerts@example.com"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "jumpbox_ssh_public_key" {
  type        = string
  description = "SSH public key for jumpbox admin access"
}

variable "jumpbox_allowed_ip" {
  type        = string
  description = "Your public IP address allowed to SSH to the jumpbox (e.g. 1.2.3.4/32)"
}