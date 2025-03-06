# LAB-13-AWS: Using Basic Terraform Functions

## Overview
In this lab, you will learn how to use a few essential Terraform built-in functions: `min`, `max`, `join`, and `toset`. These functions help you manipulate values and create more flexible infrastructure configurations. The lab uses AWS free-tier resources to ensure no costs are incurred.

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
20 minutes

## Initial Configuration Files

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}
```

### variables.tf
```hcl
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "teams" {
  description = "List of teams with duplicates"
  type        = list(string)
  default     = ["development", "operations", "security", "development"]
}
```

## Lab Steps

### 1. Configure AWS Credentials

Set up your AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

### 2. Create a Simple VPC with Join Function

Create a `main.tf` file with a VPC resource using the join function:

```hcl
# Use join function to create a VPC name
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = join("-", [var.environment, "vpc"])
    # This creates "dev-vpc" using the join function
  }
}
```

### 3. Use Min Function for Subnet Count

Add subnet resources using the min function to determine how many to create:

```hcl
# Use min function to determine how many subnets to create
# This ensures we don't try to create more subnets than we have AZs
resource "aws_subnet" "main" {
  count             = min(length(var.availability_zones), length(var.subnet_cidrs))
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-subnet-${count.index + 1}"
  }
}
```

### 4. Use Toset Function to Remove Duplicates

Create a security group with tags based on unique team names:

```hcl
# Use toset function to remove duplicates from teams list
locals {
  unique_teams = toset(var.teams)
}

# Create security group 
resource "aws_security_group" "example" {
  name        = "${var.environment}-security-group"
  description = "Example security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name  = "${var.environment}-security-group"
    Teams = join(", ", local.unique_teams)
    # This joins unique team names with commas
  }
}
```

### 5. Add Simple Outputs

Create an `outputs.tf` file with a few outputs:

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_count" {
  description = "Number of subnets created (using min function)"
  value       = min(length(var.availability_zones), length(var.subnet_cidrs))
}

output "unique_teams" {
  description = "List of unique teams (using toset function)"
  value       = local.unique_teams
}

output "security_group_name" {
  description = "Security group name (created with join function)"
  value       = aws_security_group.example.name
}
```

### 6. Apply the Configuration

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

### 7. Clean Up

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
Example: `join("-", ["dev", "vpc"])` produces `"dev-vpc"`

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