# LAB-14-AZ: Using Terraform Registry Modules

## Overview
In this lab, you will learn how to use modules from the Terraform Registry to create Azure infrastructure more efficiently. You'll use two different modules, with one module using the output from another. You'll also call the same module multiple times with different parameters to create similar but unique resources. Finally, you'll use a module with the for_each meta-argument to create multiple instances. The lab uses Azure free resources to ensure no costs are incurred.

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
25 minutes

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

### 2. Use the Resource Group Module from Terraform Registry

Create a `main.tf` file and use the Azure Resource Group module:

```hcl
# Module 1: Resource Group Module from Terraform Registry
module "resource_group" {
  source  = "Azure/resource-group/azurerm"
  version = "1.1.0"

  resource_group_name     = "${var.environment}-${var.resource_group_name}"
  resource_group_location = var.location

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
```

### 3. Use the Virtual Network Module with Resource Group Output

Add the Azure Virtual Network module, using the Resource Group name output from the first module:

```hcl
# Module 2: Virtual Network Module from Terraform Registry
# This module uses the Resource Group name output from the Resource Group module
module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"

  resource_group_name = module.resource_group.resource_group_name
  address_space       = [var.address_space]
  vnet_name           = "${var.environment}-vnet"
  subnet_names        = ["web", "app"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
```

### 4. Call the Network Security Group Module Multiple Times

Call the Network Security Group module twice with different parameters to create different security groups:

```hcl
# Module 3a: Network Security Group Module - Web Servers
module "web_security_group" {
  source  = "Azure/network-security-group/azurerm"
  version = "4.1.0"

  resource_group_name = module.resource_group.resource_group_name
  security_group_name = "${var.environment}-web-nsg"
  
  # Allow HTTP and HTTPS inbound traffic
  predefined_rules = [
    {
      name     = "HTTP"
      priority = 100
    },
    {
      name     = "HTTPS"
      priority = 110
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Role        = "web"
  }
}

# Module 3b: Network Security Group Module - App Servers
module "app_security_group" {
  source  = "Azure/network-security-group/azurerm"
  version = "4.1.0"

  resource_group_name = module.resource_group.resource_group_name
  security_group_name = "${var.environment}-app-nsg"
  
  # Create custom rules for the app tier
  custom_rules = [
    {
      name                   = "AppPort"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_port_range      = "*"
      destination_port_range = "8080"
      source_address_prefix  = "10.0.1.0/24"  # Only allow traffic from web subnet
      description            = "Allow App Port"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Role        = "app"
  }
}
```

### 5. Use Module with For_Each

Now, let's demonstrate how to use the `for_each` meta-argument with a module. Add the following to your `main.tf` file to create multiple storage accounts using the same module but with different names and configurations:

```hcl
# Module 4: Using Storage Account module with for_each
module "storage_accounts" {
  source  = "Azure/storage-account/azurerm"
  version = "3.5.0"
  
  for_each = var.storage_accounts

  storage_account_name              = "${var.environment}${each.key}sa"
  resource_group_name               = module.resource_group.resource_group_name
  location                          = var.location
  account_tier                      = "Standard"
  account_replication_type          = each.value
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  shared_access_key_enabled         = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = each.key
  }
}
```

### 6. Add Outputs

Create an `outputs.tf` file to output important information:

```hcl
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.resource_group.resource_group_id
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = module.network.vnet_subnets
}

output "web_nsg_id" {
  description = "The ID of the web network security group"
  value       = module.web_security_group.network_security_group_id
}

output "app_nsg_id" {
  description = "The ID of the app network security group"
  value       = module.app_security_group.network_security_group_id
}

output "storage_account_names" {
  description = "The names of the created storage accounts"
  value       = { for k, v in module.storage_accounts : k => v.name }
}
```

### 7. Initialize and Apply

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Notice how Terraform:
- Downloads the modules from the Terraform Registry
- Creates a resource group using the resource group module
- Creates a virtual network with subnets using the network module 
- Creates two different NSGs using the same module with different parameters
- Creates multiple storage accounts by using the same module with for_each
- Successfully references the resource group name from the first module's output

### 8. Clean Up

Remove all created resources:

```bash
terraform destroy
```

## Understanding Module Usage

Let's examine the key aspects of using modules from the Terraform Registry:

### Module Sources
The `source` attribute specifies where to find the module:
```
source = "Azure/resource-group/azurerm"
```
This format (`<NAMESPACE>/<NAME>/<PROVIDER>`) refers to modules in the public Terraform Registry.

### Module Versioning
The `version` attribute pins the module to a specific version:
```
version = "1.1.0"
```
This ensures consistent behavior even if the module is updated in the registry.

### Module Inputs
Each module accepts input variables that control its behavior:
```
resource_group_name = "${var.environment}-${var.resource_group_name}"
```

### Module Outputs
Modules provide outputs that can be used by other resources:
```
resource_group_name = module.resource_group.resource_group_name
```
Here, the resource group name output from the first module is used as an input for the second module.

### Multiple Module Instances
The same module can be called multiple times with different parameters:
```
module "web_security_group" {
  security_group_name = "${var.environment}-web-nsg"
  ...
}

module "app_security_group" {
  security_group_name = "${var.environment}-app-nsg"
  ...
}
```

### Using For_Each with Modules
Modules can be instantiated multiple times using for_each:
```
module "storage_accounts" {
  for_each = var.storage_accounts
  storage_account_name = "${var.environment}${each.key}sa"
  account_replication_type = each.value
  ...
}
```
This creates one module instance for each element in the map, with each instance receiving different input values.

## Additional Resources

- [Terraform Registry](https://registry.terraform.io/)
- [Azure Resource Group Module](https://registry.terraform.io/modules/Azure/resource-group/azurerm/latest)
- [Azure Network Module](https://registry.terraform.io/modules/Azure/network/azurerm/latest)
- [Azure Network Security Group Module](https://registry.terraform.io/modules/Azure/network-security-group/azurerm/latest)
- [Azure Storage Account Module](https://registry.terraform.io/modules/Azure/storage-account/azurerm/latest)