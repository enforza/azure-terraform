# Variables for account-specific configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "enforza-simple-gateway"
}

variable "admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM administrator password (min 12 characters)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Size of the gateway VM"
  type        = string
  default     = "Standard_B1s"
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_prefix" {
  description = "Public subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_prefix" {
  description = "Private subnet 1 address prefix"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_prefix" {
  description = "Private subnet 2 address prefix"
  type        = string
  default     = "10.0.20.0/24"
}

variable "enforza_companyId" {
  description = "Enforza company ID for agent installation"
  type        = string
}

# Local values for consistent naming
locals {
  tags = {
    Environment = "lab"
    Project     = "enforza-simple-gateway"
    ManagedBy   = "terraform"
  }
}

# Authentication validation
resource "null_resource" "auth_validation" {
  count = (var.admin_password != null && var.admin_password != "") || (var.ssh_public_key != null && var.ssh_public_key != "") ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'ERROR: Either admin_password or ssh_public_key must be provided' && exit 1"
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "enforza-gateway-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags               = local.tags
}

# Public Subnet
resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_prefix]
}

# Private Subnet 1
resource "azurerm_subnet" "private_1" {
  name                 = "private-subnet-1"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_1_prefix]
}

# Private Subnet 2
resource "azurerm_subnet" "private_2" {
  name                 = "private-subnet-2"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnet_2_prefix]
}

# Network Security Group for Enforza Gateway (Permit Any Any)
resource "azurerm_network_security_group" "gateway" {
  name                = "enforza-gateway-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags               = local.tags

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Route Table for Private Subnets (removed - no routing needed)
# resource "azurerm_route_table" "private" {
#   name                = "enforza-gateway-rt"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   tags               = local.tags
#
#   route {
#     name           = "default-via-gateway"
#     address_prefix = "0.0.0.0/0"
#     next_hop_type  = "VirtualAppliance"
#     next_hop_in_ip_address = "10.0.1.4" # Static IP for gateway VM
#   }
# }

# Associate Route Table with Private Subnet 1 (removed)
# resource "azurerm_subnet_route_table_association" "private_1" {
#   subnet_id      = azurerm_subnet.private_1.id
#   route_table_id = azurerm_route_table.private.id
# }

# Associate Route Table with Private Subnet 2 (removed)
# resource "azurerm_subnet_route_table_association" "private_2" {
#   subnet_id      = azurerm_subnet.private_2.id
#   route_table_id = azurerm_route_table.private.id
# }

# Public IP for Enforza Gateway
resource "azurerm_public_ip" "gateway" {
  name                = "enforza-gateway-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                = "Standard"
  tags               = local.tags
}

# Network Interface for Enforza Gateway
resource "azurerm_network_interface" "gateway" {
  name                 = "enforza-gateway-nic"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  ip_forwarding_enabled = true
  tags                 = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.gateway.id
  }
}

# Associate NSG to Gateway NIC
resource "azurerm_network_interface_security_group_association" "gateway" {
  network_interface_id      = azurerm_network_interface.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Enforza Gateway VM (Enforza agent configures gateway functionality)
resource "azurerm_linux_virtual_machine" "gateway" {
  name                = "enforza-gateway"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  disable_password_authentication = var.ssh_public_key != null
  tags               = local.tags

  # Authentication
  admin_password = var.ssh_public_key != null ? null : var.admin_password

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  network_interface_ids = [
    azurerm_network_interface.gateway.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Install Enforza agent (automatically configures gateway functionality)
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    curl -s -L https://go.efz.io/install | sudo bash -s -- --companyId=${var.enforza_companyId}
    EOF
  )
}

# Outputs
output "gateway_public_ip" {
  description = "Public IP address of the Enforza Gateway"
  value       = azurerm_public_ip.gateway.ip_address
}

output "gateway_private_ip" {
  description = "Private IP address of the Enforza Gateway"
  value       = azurerm_network_interface.gateway.private_ip_address
}

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "network_info" {
  description = "Network configuration summary"
  value = {
    vnet_address_space      = var.vnet_address_space[0]
    public_subnet           = var.public_subnet_prefix
    private_subnet_1        = var.private_subnet_1_prefix
    private_subnet_2        = var.private_subnet_2_prefix
    gateway_ip              = "10.0.1.4"
  }
}

output "connection_info" {
  description = "Connection information"
  value = {
    ssh_gateway = "ssh ${var.admin_username}@${azurerm_public_ip.gateway.ip_address}"
    enforza_company_id = var.enforza_companyId
    note = "Enforza Gateway configured automatically by agent with company ID: ${var.enforza_companyId}"
  }
}