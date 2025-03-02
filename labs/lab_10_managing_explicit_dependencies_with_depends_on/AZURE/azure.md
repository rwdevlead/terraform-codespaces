# LAB-10-AZURE: Managing Explicit Dependencies with `depends_on`

## Overview
This lab demonstrates how to use Terraform's `depends_on` meta-argument with Azure resources. You'll learn when to use explicit dependencies versus relying on implicit dependencies, using only free Azure resources.

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
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
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
# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "depends-on-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
  }
}

# Virtual Network
resource "azurerm_virtual_network" "example" {
  name                = "${var.environment}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "example" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.subnet_address_prefix
}

# Network Security Group
resource "azurerm_network_security_group" "example" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
  }
}

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "sa${var.environment}${formatdate("YYMMdd", timestamp())}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    Environment = var.environment
  }
}
```

## Lab Steps

### 1. Identify Implicit Dependencies

Examine the main.tf file and identify the implicit dependencies:
- Virtual Network depends on Resource Group (via resource_group_name)
- Subnet depends on Virtual Network (via virtual_network_name)
- NSG depends on Resource Group (via resource_group_name)
- Storage Account depends on Resource Group (via resource_group_name)

### 2. Initialize Terraform

Initialize your Terraform workspace:
```bash
terraform init
```

### 3. Run an Initial Plan and Apply

Create the initial resources:
```bash
terraform plan
terraform apply
```

Notice how Terraform automatically determines the correct order based on implicit dependencies.

### 4. Add NSG to Subnet (Potential Dependency Issue)

Add the following resources to main.tf:

```hcl
# Subnet NSG Association
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
```

### 5. Add Storage Containers

Add storage containers that implicitly depend on the storage account:

```hcl
# Storage Containers
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}
```

### 6. Apply the Changes

Run terraform apply again:
```bash
terraform apply
```

### 7. Add Resources with Explicit Dependencies

Now, add the following resources that require explicit dependencies:

```hcl
# Storage container with explicit dependency
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  
  # Explicitly depend on the other containers
  # This ensures the other containers are created first
  depends_on = [
    azurerm_storage_container.logs,
    azurerm_storage_container.data
  ]
}

# Network Security Group Rule with explicit dependency
resource "azurerm_network_security_rule" "https" {
  name                        = "AllowHTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  
  # Explicitly depend on the NSG association to ensure
  # the NSG is attached to the subnet before adding rules
  depends_on = [azurerm_subnet_network_security_group_association.example]
}
```

### 8. Apply and Observe Order

```bash
terraform apply
```

Watch how Terraform respects both your implicit and explicit dependencies.

### 9. Add Outputs

Create an outputs.tf file:

```hcl
output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.example.name
}

output "virtual_network_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.example.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.example.name
}

output "storage_containers" {
  description = "Names of the Storage Containers"
  value = [
    azurerm_storage_container.logs.name,
    azurerm_storage_container.data.name,
    azurerm_storage_container.backups.name
  ]
}

output "dependency_example" {
  description = "Example of dependencies in this lab"
  value = {
    "Implicit dependencies" = "Resource Group -> VNet -> Subnet, Resource Group -> NSG, Resource Group -> Storage Account"
    "Explicit dependencies" = "Logs/Data containers -> Backup container, NSG Association -> NSG Rule"
  }
}
```

### 10. Apply to See Outputs

```bash
terraform apply
```

### 11. Clean Up Resources

When you're done, clean up all resources:
```bash
terraform destroy
```

## Understanding depends_on

### When to Use depends_on:
1. When there's no implicit dependency (no reference to another resource's attributes)
2. When a resource needs to be created after another, even though they don't directly reference each other
3. When you need to ensure a specific creation order for resources

### Examples in Azure:
- Storage containers with a specific creation order
- Network security rules that should be created after NSG associations
- Resource associations that depend on both resources being completely provisioned

### Syntax:
```hcl
resource "azurerm_example" "example" {
  # ... configuration ...
  
  depends_on = [
    azurerm_other_resource.name
  ]
}
```

## Additional Exercises

1. Add an Azure Private DNS Zone that depends on the VNet
2. Create multiple storage accounts with dependencies between them
3. Set up a chain of security rules that depends on each other
4. Try adding a circular dependency and observe Terraform's error message