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
  default     = "enforza-ha-multi-az-gateway"
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
    Project     = "enforza-ha-multi-az-gateway"
    ManagedBy   = "terraform"
  }
  
  # Use first two availability zones for the region
  availability_zones = ["1", "2"]
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
  name                = "enforza-ha-gateway-vnet"
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

# Network Security Group for Enforza Gateways (Permit Any Any)
resource "azurerm_network_security_group" "gateway" {
  name                = "enforza-ha-gateway-nsg"
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

# Internal Load Balancer for HA Gateways
resource "azurerm_lb" "gateway" {
  name                = "enforza-ha-gateway-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                = "Standard"
  tags               = local.tags

  frontend_ip_configuration {
    name                          = "gateway-frontend"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.100"
  }
}

# Load Balancer Backend Pool
resource "azurerm_lb_backend_address_pool" "gateway" {
  loadbalancer_id = azurerm_lb.gateway.id
  name            = "gateway-backend-pool"
}

# Load Balancer Health Probe
resource "azurerm_lb_probe" "gateway" {
  loadbalancer_id = azurerm_lb.gateway.id
  name            = "gateway-health-probe"
  port            = 22
  protocol        = "Tcp"
}

# Load Balancer Rule for All Traffic
resource "azurerm_lb_rule" "gateway" {
  loadbalancer_id                = azurerm_lb.gateway.id
  name                           = "gateway-lb-rule"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "gateway-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.gateway.id]
  probe_id                       = azurerm_lb_probe.gateway.id
}

# Route Table for Private Subnets (pointing to Load Balancer)
resource "azurerm_route_table" "private" {
  name                = "enforza-ha-gateway-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags               = local.tags

  route {
    name           = "default-via-ha-gateway-lb"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.100" # Load Balancer IP
  }
}

# Associate Route Table with Private Subnet 1
resource "azurerm_subnet_route_table_association" "private_1" {
  subnet_id      = azurerm_subnet.private_1.id
  route_table_id = azurerm_route_table.private.id
}

# Associate Route Table with Private Subnet 2
resource "azurerm_subnet_route_table_association" "private_2" {
  subnet_id      = azurerm_subnet.private_2.id
  route_table_id = azurerm_route_table.private.id
}

# Public IPs for HA Enforza Gateways
resource "azurerm_public_ip" "gateway" {
  count               = 2
  name                = "enforza-ha-gateway-${count.index + 1}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                = "Standard"
  zones              = [local.availability_zones[count.index]]
  tags               = local.tags
}

# Network Interfaces for HA Enforza Gateways
resource "azurerm_network_interface" "gateway" {
  count               = 2
  name                = "enforza-ha-gateway-${count.index + 1}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_forwarding_enabled = true
  tags               = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${count.index + 4}" # .4 and .5
    public_ip_address_id          = azurerm_public_ip.gateway[count.index].id
  }
}

# Associate NSGs to Gateway NICs
resource "azurerm_network_interface_security_group_association" "gateway" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.gateway[count.index].id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Backend Address Pool Associations
resource "azurerm_network_interface_backend_address_pool_association" "gateway" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.gateway[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.gateway.id
}

# HA Enforza Gateway VMs (Enforza agent configures gateway functionality)
resource "azurerm_linux_virtual_machine" "gateway" {
  count               = 2
  name                = "enforza-ha-gateway-${count.index + 1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  disable_password_authentication = var.ssh_public_key != null
  availability_set_id = null
  zone               = local.availability_zones[count.index]
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
    azurerm_network_interface.gateway[count.index].id,
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
output "gateway_public_ips" {
  description = "Public IP addresses of the HA Enforza Gateways"
  value       = azurerm_public_ip.gateway[*].ip_address
}

output "gateway_private_ips" {
  description = "Private IP addresses of the HA Enforza Gateways"
  value       = azurerm_network_interface.gateway[*].private_ip_address
}

output "load_balancer_ip" {
  description = "Private IP address of the Load Balancer"
  value       = azurerm_lb.gateway.frontend_ip_configuration[0].private_ip_address
}



output "availability_zones" {
  description = "Availability zones used for the gateways"
  value       = local.availability_zones
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
    gateway_1_ip            = "10.0.1.4"
    gateway_2_ip            = "10.0.1.5"
    load_balancer_ip        = "10.0.1.100"
    default_route_via       = "10.0.1.100"
  }
}

output "connection_info" {
  description = "Connection information"
  value = {
    ssh_gateway_1 = "ssh ${var.admin_username}@${azurerm_public_ip.gateway[0].ip_address}"
    ssh_gateway_2 = "ssh ${var.admin_username}@${azurerm_public_ip.gateway[1].ip_address}"
    enforza_company_id = var.enforza_companyId
    note = "HA Enforza Gateways in AZs ${join(",", local.availability_zones)} with Load Balancer routing"
    architecture = "Private subnets route via Load Balancer (${azurerm_lb.gateway.frontend_ip_configuration[0].private_ip_address}) to HA Gateways"
  }
}