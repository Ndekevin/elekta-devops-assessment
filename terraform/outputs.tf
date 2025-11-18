output "vm1_name" {
  description = "Name of VM 1"
  value       = azurerm_windows_virtual_machine.vm1.name
}

output "vm2_name" {
  description = "Name of VM 2"
  value       = azurerm_windows_virtual_machine.vm2.name
}

output "vm1_public_ip" {
  description = "Public IP address of VM 1"
  value       = azurerm_public_ip.vm1.ip_address
}

output "vm2_public_ip" {
  description = "Public IP address of VM 2"
  value       = azurerm_public_ip.vm2.ip_address
}

output "vm1_private_ip" {
  description = "Private IP address of VM 1"
  value       = azurerm_network_interface.vm1.private_ip_address
}

output "vm2_private_ip" {
  description = "Private IP address of VM 2"
  value       = azurerm_network_interface.vm2.private_ip_address
}

output "virtual_network_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID of the Subnet"
  value       = azurerm_subnet.internal.id
}