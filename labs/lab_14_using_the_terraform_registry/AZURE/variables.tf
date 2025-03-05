variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "main-resources"
}

variable "storage_accounts" {
  description = "Map of storage accounts to create"
  type        = map(string)
  default = {
    "logs"      = "Standard_LRS"
    "artifacts" = "Standard_LRS"
    "configs"   = "Standard_LRS"
  }
}