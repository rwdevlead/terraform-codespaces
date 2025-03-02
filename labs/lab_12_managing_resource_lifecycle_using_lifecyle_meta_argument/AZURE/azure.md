# LAB-12-AZURE: Managing Resource Lifecycles with lifecycle Meta-Argument

## Overview
This lab demonstrates how to use Terraform's `lifecycle` meta-argument to control the creation, update, and deletion behavior of Azure resources. You'll learn how to prevent resource destruction, create resources before destroying old ones, and ignore specific changes.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- Azure free account
- Basic understanding of Terraform and Azure concepts

Note: Azure credentials are required for this lab.

## How to Use This Hands-On Lab

1. **Create a Codespace** from this repo (click the button below).  
2. Once the Codespace is running, open the integrated terminal.
3. Follow the instructions in each **lab** to complete the exercises.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/btkrausen/terraform-codespaces)

## Estimated Time
15 minutes

## Existing Configuration Files

The lab directory contains the following initial files:

### variables.tf
```hcl
variable "location" {
  description = "Azure location"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### main.tf
```hcl
# Resource Group without lifecycle configuration
resource "azurerm_resource_group" "standard" {
  name     = "rg-standard-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Purpose     = "Standard"
  }
}

# Storage Account without lifecycle configuration
resource "azurerm_storage_account" "standard" {
  name                     = "standardsa${formatdate("YYMMdd", timestamp())}"
  resource_group_name      = azurerm_resource_group.standard.name
  location                 = azurerm_resource_group.standard.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Purpose     = "Standard"
  }
}
```

## Lab Steps

### 1. Initialize Terraform

Initialize your Terraform workspace:
```bash
terraform init
```

### 2. Examine the Initial Configuration

Notice the resources in main.tf do not have any lifecycle configuration.

### 3. Run an Initial Apply

Create the initial resources:
```bash
terraform plan
terraform apply
```

### 4. Add prevent_destroy Lifecycle Configuration

Add a new resource group with the `prevent_destroy` lifecycle configuration:

```hcl
# Resource Group with prevent_destroy
resource "azurerm_resource_group" "protected" {
  name     = "rg-protected-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Purpose     = "Protected"
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

### 5. Apply the Changes

Apply the configuration to create the protected resource group:
```bash
terraform apply
```

### 6. Try to Destroy the Protected Resource Group

Modify main.tf to comment out or remove the protected resource group:

```hcl
# Resource Group with prevent_destroy
# resource "azurerm_resource_group" "protected" {
#   name     = "rg-protected-${var.environment}"
#   location = var.location
#
#   tags = {
#     Environment = var.environment
#     Purpose     = "Protected"
#   }
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }
```

Apply the change and observe the error:
```bash
terraform apply
```

Terraform should prevent you from destroying the protected resource group.

### 7. Restore the Protected Resource Group

Uncomment or restore the protected resource group in main.tf.

### 8. Add create_before_destroy Lifecycle Configuration

Add a storage account with the `create_before_destroy` lifecycle configuration:

```hcl
# Storage Account with create_before_destroy
resource "azurerm_storage_account" "replacement" {
  name                     = "replacesa${formatdate("YYMMdd", timestamp())}"
  resource_group_name      = azurerm_resource_group.standard.name
  location                 = azurerm_resource_group.standard.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
    Purpose     = "Replacement"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### 9. Apply to Create the Replacement Storage Account
```bash
terraform apply
```

### 10. Add ignore_changes Lifecycle Configuration

Add an App Service Plan with the `ignore_changes` lifecycle configuration to ignore specific attributes:

```hcl
# App Service Plan with ignore_changes
resource "azurerm_service_plan" "updates" {
  name                = "sp-updates-${var.environment}"
  resource_group_name = azurerm_resource_group.standard.name
  location            = azurerm_resource_group.standard.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    Environment = var.environment
    Purpose     = "Updates"
    Version     = "1.0.0"  # This will be ignored
  }

  lifecycle {
    ignore_changes = [
      tags["Version"]
    ]
  }
}
```

### 11. Apply to Create the App Service Plan
```bash
terraform apply
```

### 12. Update the Version Tag

Let's simulate changing the Version tag outside of Terraform by updating it in our Terraform configuration:

```hcl
# App Service Plan with ignore_changes
resource "azurerm_service_plan" "updates" {
  name                = "sp-updates-${var.environment}"
  resource_group_name = azurerm_resource_group.standard.name
  location            = azurerm_resource_group.standard.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    Environment = var.environment
    Purpose     = "Updates"
    Version     = "2.0.0"  # Changed but will be ignored
  }

  lifecycle {
    ignore_changes = [
      tags["Version"]
    ]
  }
}
```

### 13. Apply and Observe Behavior
```bash
terraform plan
terraform apply
```

Notice that Terraform doesn't try to update the Version tag since we've configured it to ignore changes to this attribute.

### 14. Create outputs.tf

Create an outputs.tf file:

```hcl
output "standard_resource_group_name" {
  description = "Name of the standard resource group"
  value       = azurerm_resource_group.standard.name
}

output "protected_resource_group_name" {
  description = "Name of the protected resource group"
  value       = azurerm_resource_group.protected.name
}

output "standard_storage_account_name" {
  description = "Name of the standard storage account"
  value       = azurerm_storage_account.standard.name
}

output "replacement_storage_account_name" {
  description = "Name of the replacement storage account"
  value       = azurerm_storage_account.replacement.name
}

output "app_service_plan_name" {
  description = "Name of the app service plan"
  value       = azurerm_service_plan.updates.name
}

output "lifecycle_examples" {
  description = "Examples of lifecycle configurations used"
  value = {
    "prevent_destroy"      = "Resource group protected from accidental deletion"
    "create_before_destroy" = "Storage account created before replacing"
    "ignore_changes"       = "App Service Plan ignores changes to Version tag"
  }
}
```

### 15. Apply to See Outputs
```bash
terraform apply
```

### 16. Clean Up Resources

When you're done, remove the `prevent_destroy` lifecycle setting from the protected resource group first:

```hcl
# Resource Group with prevent_destroy removed
resource "azurerm_resource_group" "protected" {
  name     = "rg-protected-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Purpose     = "Protected"
  }

  # Lifecycle block removed or modified
}
```

Then clean up all resources:
```bash
terraform apply  # Apply the removal of prevent_destroy first
terraform destroy
```

## Understanding the lifecycle Meta-Argument

### prevent_destroy
- Prevents Terraform from destroying the resource
- Useful for protecting critical resources like databases, production environments
- Must be removed before you can destroy the resource

### create_before_destroy
- Creates the replacement resource before destroying the existing one
- Useful for minimizing downtime during replacements
- Works well for resources that can exist in parallel temporarily

### ignore_changes
- Tells Terraform to ignore changes to specific attributes
- Useful when attributes are modified outside of Terraform
- Can be applied to specific attributes or all attributes with `ignore_changes = all`

### Syntax:
```hcl
resource "azurerm_example" "example" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
    create_before_destroy = true
    ignore_changes = [
      tags,
      attribute_name
    ]
  }
}
```