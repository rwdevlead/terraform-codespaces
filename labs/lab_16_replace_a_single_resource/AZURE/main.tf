# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-resources-${random_string.suffix.result}"
  location = var.location

  tags = {
    Name        = var.resource_group_tag_name
    Environment = var.environment
  }
}

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "${var.prefix}stor${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication

  tags = {
    Environment = var.environment
  }
}

# App Service Plan
resource "azurerm_service_plan" "example" {
  name                = "${var.prefix}-plan-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "F1" # Free tier

  tags = {
    Environment = var.environment
  }
}

# Random string for resource name uniqueness
resource "random_string" "suffix" {
  length  = var.random_suffix_length
  special = var.special_chars_allowed
  upper   = var.upper_chars_allowed
}