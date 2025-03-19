# LAB-16-AZURE: Replacing and Removing Resources in Terraform

## Overview
In this lab, you will learn how to replace and remove resources in Terraform when working with Azure. You'll practice using the `-replace` flag and removing resources from configuration using free Azure resources.

## Prerequisites
- Terraform installed (v1.0.0+)
- Azure account
- Azure CLI installed and configured

## Estimated Time
30 minutes

## Initial Configuration Files

Create the following files in your working directory:

### variables.tf
```hcl
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
```

### main.tf
```hcl
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
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### outputs.tf
```hcl
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
```

## Lab Steps

### 1. Initialize and Apply
Login to Azure first:

```bash
az login
```

Then initialize Terraform and create the resources:

```bash
terraform init
terraform apply -auto-approve
```

### 2. Replace a Resource Using the `-replace` Flag

Let's replace the storage account without changing its configuration:

```bash
terraform apply -replace="azurerm_storage_account.example" -auto-approve
```

Observe in the output how Terraform:
- Destroys the existing storage account
- Creates a new storage account with the same configuration

### 3. Replace a Resource by Modifying Configuration

Let's update the variables to change resource configurations. Create a file called `modified.tfvars`:

```hcl
prefix = "tflab16mod"
resource_group_tag_name = "Modified Resource Group"
environment = "test"
```

Apply with the new variables:

```bash
terraform apply -var-file="modified.tfvars" -auto-approve
```

Observe how Terraform plans to replace the resource group and storage account due to name changes.

### 4. Remove a Resource by Deleting it from Configuration

Remove or comment out the App Service Plan resource from main.tf:

```hcl
# App Service Plan
# resource "azurerm_service_plan" "example" {
#   name                = "${var.prefix}-plan-${random_string.suffix.result}"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   os_type             = "Linux"
#   sku_name            = "F1" # Free tier
#
#   tags = {
#     Environment = var.environment
#   }
# }
```

Also comment out the related output:

```hcl
# output "app_service_plan_name" {
#   description = "Name of the created app service plan"
#   value       = azurerm_service_plan.example.name
# }
```

Apply the changes:

```bash
terraform apply -auto-approve
```

Observe that Terraform plans to destroy the App Service Plan.

### 5. Remove a Resource Using `terraform destroy -target`

Now, let's remove the storage account using targeted destroy without changing the configuration:

```bash
terraform destroy -target=azurerm_storage_account.example -auto-approve
```

Verify it's gone:

```bash
terraform state list
```

Run a normal apply to recreate it:

```bash
terraform apply -auto-approve
```

### 6. Add a Resource back to Configuration

Let's add back the App Service Plan we removed earlier by uncommenting the resource and output.

Apply the changes:

```bash
terraform apply -auto-approve
```

Observe that Terraform plans to create the App Service Plan again.

### 7. Clean Up

When finished, clean up all resources:

```bash
terraform destroy -auto-approve
```

## Key Concepts

### Resource Replacement Methods
- **Using `-replace` flag**: Forces resource recreation without configuration changes
- **Changing force-new attributes**: Some attribute changes automatically trigger replacement

### Resource Removal Methods
- **Removing from configuration**: Delete the resource block from your .tf files
- **Using `terraform destroy -target`**: Temporarily removes a resource; it will be recreated on next apply

## Additional Challenge

1. Add an Azure Function App (Consumption plan) to the configuration, then practice replacing and removing it
2. Create a terraform.tfvars file that changes multiple variables at once, then observe which resources get replaced
3. Try using `-replace` with a resource that has dependencies and observe how Terraform handles the dependencies