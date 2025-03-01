# LAB-06-AZ: Refactoring Terraform Configurations: Making Code Dynamic and Reusable

## Overview
In this lab, you will examine an existing Terraform configuration with hardcoded values and refactor it to be more dynamic and reusable. You'll implement variables, data sources, and string interpolation to create a more flexible infrastructure definition. The lab uses Azure free-tier eligible resources to ensure no costs are incurred.

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
45 minutes

## Existing Configuration Files

The lab directory contains the following files with hardcoded values that we'll refactor:

### main.tf
```hcl
# Static configuration with hardcoded values
resource "azurerm_resource_group" "production" {
  name     = "production-resources"
  location = "eastus"

  tags = {
    Environment = "production"
    Project     = "static-infrastructure"
    ManagedBy   = "manual-deployment"
    Region      = "eastus"
  }
}

resource "azurerm_virtual_network" "production" {
  name                = "production-network"
  resource_group_name = azurerm_resource_group.production.name
  location            = azurerm_resource_group.production.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "production"
    Project     = "static-infrastructure"
    ManagedBy   = "manual-deployment"
    Region      = "eastus"
  }
}

resource "azurerm_subnet" "private" {
  name                 = "production-subnet"
  resource_group_name  = azurerm_resource_group.production.name
  virtual_network_name = azurerm_virtual_network.production.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Examine these files and notice:
- Hardcoded resource group name and location
- Static virtual network address space
- Static subnet address prefix
- Repeated tag values across resources
- Manual environment naming
- Static project naming

## Lab Steps

### 1. Configure Azure Credentials

First, authenticate with Azure:

```bash
az login
```

If you haven't authenticated before, this will open a web browser for you to sign in. After signing in, you should see your subscription information displayed in the terminal. Set your ARM_SUBSCRIPTION_ID environment variable:

```bash
export ARM_SUBSCRIPTION_ID=12345abdce
```

### 2. Create Variables File

Create `variables.tf` to define variables that will replace hardcoded values:

```hcl
variable "environment" {
  description = "Environment name for resource naming and tagging"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "Address prefix for subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "dynamic-infrastructure"
}
```

### 3. Add Data Sources

Update `main.tf` to include data sources at the top of the file:

```hcl
# Get information about the current client configuration
data "azurerm_client_config" "current" {}

# Get information about the current subscription
data "azurerm_subscription" "current" {}
```

### 4. Refactor Resources

Replace the existing resources in `main.tf` with this dynamic configuration:

```hcl
resource "azurerm_resource_group" "dynamic" {
  name     = "${var.environment}-resources"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Region      = var.location
    Subscription = data.azurerm_subscription.current.display_name
    TenantId    = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_virtual_network" "dynamic" {
  name                = "${var.environment}-network"
  resource_group_name = azurerm_resource_group.dynamic.name
  location            = azurerm_resource_group.dynamic.location
  address_space       = var.vnet_address_space

  tags = {
    Environment  = var.environment
    Project      = var.project_name
    ManagedBy    = "terraform"
    Region       = var.location
    Subscription = data.azurerm_subscription.current.display_name
  }
}

resource "azurerm_subnet" "dynamic" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.dynamic.name
  virtual_network_name = azurerm_virtual_network.dynamic.name
  address_prefixes     = var.subnet_prefix
}
```

### 5. Create Outputs File

Create `outputs.tf` to display resource information:

```hcl
output "resource_group_id" {
  description = "ID of the created Resource Group"
  value       = azurerm_resource_group.dynamic.id
}

output "vnet_id" {
  description = "ID of the created Virtual Network"
  value       = azurerm_virtual_network.dynamic.id
}

output "subscription_info" {
  description = "Azure Subscription Information"
  value       = "${data.azurerm_subscription.current.display_name} (${data.azurerm_subscription.current.subscription_id})"
}

output "tenant_id" {
  description = "Azure Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}
```

### 6. Create Environment Configuration

Create `terraform.tfvars` to define environment-specific values:

```hcl
environment        = "development"
location           = "eastus"
vnet_address_space = ["172.16.0.0/16"]
subnet_prefix      = ["172.16.1.0/24"]
project_name       = "dynamic-infrastructure"
```

### 7. Apply and Verify

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

### 8. Test Configuration Flexibility

Create a file called `westus.tfvars` to deploy to a different region:

```hcl
environment        = "production"
location           = "westus"
vnet_address_space = ["192.168.0.0/16"]
subnet_prefix      = ["192.168.1.0/24"]
project_name       = "dynamic-infrastructure"
```

Apply the new configuration:
```bash
terraform plan -var-file="westus.tfvars"
terraform apply -var-file="westus.tfvars"
```

Notice how:
- Resources are created in West US region
- Different address spaces are used
- All region-specific tags update automatically
- The resource names reflect the "production" environment

## Understanding the Changes

Let's examine how the refactoring improves the configuration:

1. Variable Usage:
   - Resource locations are now configurable
   - Address spaces can be changed
   - Environment name can be changed
   - Project name is defined once and reused

2. Data Sources:
   - Subscription information is dynamically determined
   - Tenant information is automatically included
   - Client configuration details are available

3. String Interpolation:
   - Resource names include environment
   - Tags combine variables and data source values
   - Consistent naming across resources

## Verification Steps

1. Check the Azure Portal to verify:
   - Resources are created with dynamic names
   - Tags include subscription and tenant information
   - Resources are in the correct region
   - All resources are properly connected

2. Test the variable system:
   - Modify values in terraform.tfvars
   - Observe how changes affect the infrastructure

## Clean Up

Remove all created resources:

```bash
terraform destroy
```

## Additional Exercises
1. Create additional variable files for different environments
2. Add more data sources to query Azure information
3. Implement conditional resource creation based on variables
4. Add variable validation rules

## Common Issues and Solutions

If you encounter errors:
- Verify Azure authentication is current (run `az login` if needed)
- Ensure address spaces don't overlap with existing resources
- Check that the specified locations are valid
- Verify variable values are properly formatted