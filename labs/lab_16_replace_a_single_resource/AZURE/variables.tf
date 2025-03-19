variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tflab16"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "random_suffix_length" {
  description = "Length of random suffix for unique resource names"
  type        = number
  default     = 8
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "resource_group_tag_name" {
  description = "Name tag for the resource group"
  type        = string
  default     = "Example Resource Group"
}

variable "special_chars_allowed" {
  description = "Allow special characters in random string"
  type        = bool
  default     = false
}

variable "upper_chars_allowed" {
  description = "Allow uppercase characters in random string"
  type        = bool
  default     = false
}