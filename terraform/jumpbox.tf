# ─── Subnet ───────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "jumpbox" {
  name                 = "${local.prefix}-snet-jumpbox"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.3.0/24"]
  depends_on           = [azurerm_virtual_network.this]
}

# ─── NSG ──────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "jumpbox" {
  name                = "${local.prefix}-nsg-jumpbox"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.jumpbox_allowed_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutboundToPrivateEndpoints"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = var.subnet_private_endpoints_cidr
  }

  security_rule {
    name                       = "AllowOutboundAzureMonitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.3.0/24"
    destination_address_prefix = "AzureMonitor"
  }

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

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = azurerm_subnet.jumpbox.id
  network_security_group_id = azurerm_network_security_group.jumpbox.id
}

# ─── Public IP ────────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "jumpbox" {
  name                = "${local.prefix}-jumpbox-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# ─── Network Interface ────────────────────────────────────────────────────────

resource "azurerm_network_interface" "jumpbox" {
  name                = "${local.prefix}-jumpbox-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpbox.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }
}

# ─── Virtual Machine ──────────────────────────────────────────────────────────

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                            = "${local.prefix}-jumpbox-vm"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = "Standard_D2s_v6"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.jumpbox.id]
  tags                            = local.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.jumpbox_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ─── Output ───────────────────────────────────────────────────────────────────

output "jumpbox_public_ip" {
  description = "Public IP address of the jumpbox VM"
  value       = azurerm_public_ip.jumpbox.ip_address
}