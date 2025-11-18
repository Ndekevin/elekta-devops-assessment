#!/bin/bash

# Terraform Import Script for Elekta DevOps Assessment
# This script imports all existing Azure resources into Terraform state
# Run this from your terraform directory

SUBSCRIPTION_ID="12bdf57d-4542-42de-9a69-ef9b66eca01e"
RESOURCE_GROUP="elekta-devops-test"
RG_VNET="vnet-${RESOURCE_GROUP}"

echo "Starting resource imports..."

# Already imported - skip if you've done these
# terraform import azurerm_resource_group.main ${RESOURCE_GROUP}
# terraform import azurerm_virtual_network.main /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${RG_VNET}
# terraform import azurerm_subnet.internal /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${RG_VNET}/subnets/subnet-prod
# terraform import azurerm_network_security_group.main /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkSecurityGroups/nsg-prod
# terraform import azurerm_public_ip.vm1 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/publicIPAddresses/pip-vm-test-1
# terraform import azurerm_public_ip.vm2 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/publicIPAddresses/pip-vm-test-2

# Still need to import - uncomment and run
terraform import azurerm_network_interface.vm1 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkInterfaces/nic-vm-test-1

terraform import azurerm_network_interface.vm2 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/networkInterfaces/nic-vm-test-2

terraform import azurerm_subnet_network_security_group_association.internal /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${RG_VNET}/subnets/subnet-prod/providers/Microsoft.Network/networkSecurityGroups/nsg-prod

terraform import azurerm_windows_virtual_machine.vm1 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/vm-test-1

terraform import azurerm_windows_virtual_machine.vm2 /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/vm-test-2

echo "Imports complete! Now run: terraform plan -out=tfplan && terraform apply tfplan"