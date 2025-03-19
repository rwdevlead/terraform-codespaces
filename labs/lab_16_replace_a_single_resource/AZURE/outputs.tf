output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.example.name
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.example.name
}

output "app_service_plan_name" {
  description = "Name of the created app service plan"
  value       = azurerm_service_plan.example.name
}