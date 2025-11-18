resource "azurerm_resource_group" "main" {
    name = var.resource_group_name
    location = var.location
    tags = {
        Environment =  var.environment
        ManagedBy  = "Terraform"
    }
}

resource "azurerm_virtual_network" "main" {
    name                = "vnet-${var.resource_group_name}"
    address_space       = [var.vnet_address_space]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
    tags = {
        Environment =  var.environment
        ManagedBy  = "Terraform"
    }
}

#----------------------subnet configuration-----------------------------

resource "azurerm_subnet" "internal" {
    name = "subnet-${var.environment}"
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = [var.subnet_address_prefix]
}

#----------------------Network Security Group-----------------------------

resource "azurerm_network_security_group" "main" {
    name = "nsg-${var.environment}"
    location = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    # Allow RDP from anywhere (consider restricting in production)

    security_rule {
        name = "Allow-RDP"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "3389"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    # Allow communication between VMs on all ports

    security_rule {
        name = "AllowInternalTraffic"
        priority = 101
        direction = "Inbound"
        access = "Allow"
        protocol = "*"
        source_port_range = "*"
        destination_port_range = "*"
        source_address_prefix = var.subnet_address_prefix
        destination_address_prefix = "*"
    }

    # Allow outbound internet traffic
    security_rule {
        name                       = "AllowOutbound"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        Environment = var.environment
        ManagedBy   = "Terraform"
    }


}



