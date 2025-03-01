# LAB-06-AWS: Refactoring Terraform Configurations: Making Code Dynamic and Reusable

## Overview
In this lab, you will examine an existing Terraform configuration with hardcoded values and refactor it to be more dynamic and reusable. You'll implement variables, data sources, and string interpolation to create a more flexible infrastructure definition. The lab uses AWS free-tier eligible resources to ensure no costs are incurred.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- AWS free tier account
- Basic understanding of Terraform and AWS concepts

Note: AWS credentials are required for this lab.

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
resource "aws_vpc" "production" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "production-vpc"
    Environment = "production"
    Project = "static-infrastructure"
    ManagedBy = "manual-deployment"
    Region = "us-east-1"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.static.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "production-private-subnet"
    Environment = "production"
    Project = "static-infrastructure"
    ManagedBy = "terraform"
    Region = "us-east-1"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name = "production-route-table"
    Environment = "production"
    Project = "static-infrastructure"
    ManagedBy = "terraform"
    Region = "us-east-1"
  }
}
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

Examine these files and notice:
- Hardcoded CIDR blocks for VPC and subnet
- Static region and availability zone references
- Repeated tag values across resources
- Manual environment naming
- Static project naming

## Lab Steps

### 1. Configure AWS Credentials

Set up your AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

### 2. Create Variables File

Create `variables.tf` to define variables that will replace hardcoded values:

```hcl
variable "environment" {
  description = "Environment name for resource naming and tagging"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
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
# Retrieve the availability zones in the target region
data "aws_availability_zones" "available" {
  state = "available"
}

# Retrieve information about the target region
data "aws_region" "current" {}

# Retrieve information about the user and account
data "aws_caller_identity" "current" {}
```

### 4. Refactor Resources

Replace the existing resources in `main.tf` with this dynamic configuration:

```hcl
resource "aws_vpc" "dynamic" {
  cidr_block           = var.vpc_cidr # <-- update value here
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc" # <-- update value here
    Environment = var.environment # <-- update value here
    Project = var.project_name # <-- update value here
    ManagedBy = "terraform"
    Region = data.aws_region.current.name # <-- update value here
    AccountID = data.aws_caller_identity.current.account_id # <-- update value here
  }
}

resource "aws_subnet" "dynamic" {
  vpc_id                  = aws_vpc.production.id # <-- update value here
  cidr_block              = var.subnet_cidr # <-- update value here
  availability_zone       = data.aws_availability_zones.available.names[0] # <-- update value here
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-private-subnet" # <-- update value here
    Environment = var.environment # <-- update value here
    Project = var.project_name # <-- update value here
    ManagedBy = "terraform"
    Region = data.aws_region.current.name # <-- update value here
    AZ = data.aws_availability_zones.available.names[0] # <-- update value here
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.production.id # <-- update value here

  tags = {
    Name = "${var.environment}-route-table" # <-- update value here
    Environment = var.environment # <-- update value here
    Project = var.project_name # <-- update value here
    ManagedBy = "terraform"
    Region = data.aws_region.current.name # <-- update value here
  }
}
```

### 5. Create Outputs File

Create `outputs.tf` to display resource information:

```hcl
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.production.id
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = aws_subnet.production.id
}

output "availability_zone" {
  description = "Availability zone of the subnet"
  value       = aws_subnet.private.availability_zone
}

output "account_info" {
  description = "AWS Account Information"
  value       = "${data.aws_caller_identity.current.account_id} (${data.aws_region.current.name})"
}
```

### 6. Create Environment Configuration

Create `terraform.tfvars` to define environment-specific values:

```hcl
environment  = "development"
vpc_cidr     = "172.16.0.0/16"
subnet_cidr  = "172.16.1.0/24"
project_name = "dynamic-infrastructure"
```

### 7. Apply and Verify

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

## Understanding the Changes

Let's examine how the refactoring improves the configuration:

1. Variable Usage:
   - CIDR blocks are now configurable
   - Environment name can be changed
   - Project name is defined once and reused

2. Data Sources:
   - Region is dynamically determined
   - Availability zones are queried from AWS
   - Account information is automatically included

3. String Interpolation:
   - Resource names include environment
   - Tags combine variables and data source values
   - Consistent naming across resources

## Verification Steps

1. Check the AWS Console to verify:
   - Resources are created with dynamic names
   - Tags include account and region information
   - The subnet is in the first available AZ
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
2. Add more data sources to query AWS information
3. Implement conditional resource creation based on variables
4. Add variable validation rules

## Common Issues and Solutions

If you encounter errors:
- Verify AWS credentials are set correctly
- Ensure CIDR blocks don't overlap with existing resources
- Check that the region has available AZs
- Verify variable values are properly formatted