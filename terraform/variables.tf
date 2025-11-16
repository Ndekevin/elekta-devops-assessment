variable azure_subscription_id {
    description = "The Subscription ID for the Azure account."
    type        = string
    sensitive = true
}

variable "resource_group_name" {
    description = "Name of the Azure Resource Group"
    type = string
    default = "elekta-devops-test"
}

variable "location" {
    description = "Azure region for resources"
    type        = string
    default     = "eastus"
}

variable "vnet_address_space" {
    description = " Address prefix for Subnet"
    type = string
    default = "10.0.0.0/16"
}

variable "subnet_address_prefix" {
    description = " Address prefix for Subnet"
    type = string
    default = "10.0.1.0/24"
}

variable "vm_size" {
    description = "Size of the Virtual Machine"
    type = string
    default = "Standard_B2s"
}

variable "admin_username" {
    description = "Admin username for VMs"
    type = string
    default = "Elekta"
    sensitive = true
}

variable "admin_password" {
    description = "Admin password for VMs"
    type = string
    sensitive = true
    # This should come from terraform.tfvars or environment variables
}

variable "environment" {
    description = "Deployment environment"
    type        = string
    default     = "prod"
}

