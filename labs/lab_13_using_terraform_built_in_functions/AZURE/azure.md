# LAB-13-AZ: Using Basic Terraform Functions

## Overview
In this lab, you will learn how to use a few essential Terraform built-in functions: `min`, `max`, `join`, and `toset`. These functions help you manipulate values and create more flexible infrastructure configurations. The lab uses Azure free-tier resources to ensure no costs are incurred.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- Azure free account
- Basic understanding of Terraform and Azure concepts

Note: Azure credentials are required for this lab.

## Estimated Time
20 minutes

## Initial Configuration Files

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### variables.tf
```hcl
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

variable "address_spaces" {
  description = "List of address spaces for virtual networks"
  type        = list(string)
  default     = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
}

variable "subnet_prefixes" {
  description = "List of subnet address prefixes"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "teams" {
  description = "List of teams with duplicates"
  type        = list(string)
  default     = ["development", "operations", "security", "development"]
}
```

## Lab Steps

### 1. Configure Azure Credentials

Make sure you're authenticated with Azure:

```bash
az login
```

If you're in a codespace, you might need to use device code authentication:
```bash
az login --use-device-code
```

### 2. Create a Resource Group with Join Function

Create a `main.tf` file with a resource group using the join function:

```hcl
# Use join function to create a resource group name
resource "azurerm_resource_group" "main" {
  name     = join("-", [var.environment, "resources"])
  location = var.location

  tags = {
    Environment = var.environment
    # This creates "dev-resources" using the join function
  }
}
```

### 3. Use Min Function for Virtual Network Count

Add virtual network resources using the min function to determine how many to create:

```hcl
# Use min function to determine how many virtual networks to create
resource "azurerm_virtual_network" "main" {
  count               = min(2, length(var.address_spaces))
  name                = "${var.environment}-vnet-${count.index + 1}"
  address_space       = [var.address_spaces[count.index]]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name = "${var.environment}-vnet-${count.index + 1}"
  }
}
```

### 4. Create Subnets with Min Function

Add subnet resources using the min function:

```hcl
# Use min function to limit subnet count
resource "azurerm_subnet" "main" {
  count                = min(length(var.subnet_prefixes), 3)
  name                 = "${var.environment}-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.subnet_prefixes[count.index]]
}
```

### 5. Use Toset Function to Remove Duplicates

Create a network security group with tags based on unique team names:

```hcl
# Use toset function to remove duplicates from teams list
locals {
  unique_teams = toset(var.teams)
}

# Create network security group
resource "azurerm_network_security_group" "example" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Name  = "${var.environment}-nsg"
    Teams = join(", ", local.unique_teams)
    # This joins unique team names with commas
  }
}
```

### 6. Add Simple Outputs

Create an `outputs.tf` file with a few outputs:

```hcl
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_count" {
  description = "Number of virtual networks created (using min function)"
  value       = min(2, length(var.address_spaces))
}

output "subnet_count" {
  description = "Number of subnets created (using min function)"
  value       = min(length(var.subnet_prefixes), 3)
}

output "unique_teams" {
  description = "List of unique teams (using toset function)"
  value       = local.unique_teams
}

output "nsg_name" {
  description = "NSG name (created with join function)"
  value       = azurerm_network_security_group.example.name
}
```

### 7. Apply the Configuration

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Observe how the functions work:
- `join` creates string values by combining elements
- `min` calculates the minimum value between two numbers
- `toset` converts a list to a set, removing duplicates

### 8. Clean Up

Remove all created resources:

```bash
terraform destroy
```

## Function Reference

### Join Function
The `join` function combines a list of strings with a specified delimiter.
```
join(separator, list)
```
Example: `join("-", ["dev", "resources"])` produces `"dev-resources"`

### Min Function
The `min` function returns the minimum value from a set of numbers.
```
min(number1, number2, ...)
```
Example: `min(3, 5)` produces `3`

### Toset Function
The `toset` function converts a list to a set, removing any duplicate elements.
```
toset(list)
```
Example: `toset(["a", "b", "a", "c"])` produces `["a", "b", "c"]`