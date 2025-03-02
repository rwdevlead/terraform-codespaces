# LAB-11-AWS: Deploying Resources to Multiple Regions

## Overview
This lab demonstrates how to use multiple provider blocks in Terraform to deploy resources to different AWS regions simultaneously. You'll create resources in two regions using a simple, free configuration.

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
10 minutes

## Existing Configuration Files

The lab directory contains the following initial files:

### variables.tf
```hcl
variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-2"
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
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Primary region provider
provider "aws" {
  region = var.primary_region
  alias  = "primary"
}

# Secondary region provider
provider "aws" {
  region = var.secondary_region
  alias  = "secondary"
}
```

### main.tf
```hcl
# S3 Bucket in primary region
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "primary-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Primary Region Bucket"
    Environment = var.environment
    Region      = var.primary_region
  }
}

# S3 Bucket in secondary region
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "secondary-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Secondary Region Bucket"
    Environment = var.environment
    Region      = var.secondary_region
  }
}

# Random string for bucket name uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
```

## Lab Steps

### 1. Initialize Terraform

Initialize your Terraform workspace:
```bash
terraform init
```

### 2. Examine the Provider Configuration

Notice how the provider blocks are configured in providers.tf:
- The primary provider with an alias of "primary"
- The secondary provider with an alias of "secondary"

### 3. Examine the Resource Configuration

Look at how resources specify which provider to use:
- `provider = aws.primary` for resources in the primary region
- `provider = aws.secondary` for resources in the secondary region

### 4. Run Plan and Apply

Create the resources in both regions:
```bash
terraform plan
terraform apply
```

### 5. Add SNS Topics to Both Regions

Add the following resources to main.tf:

```hcl
# SNS Topic in primary region
resource "aws_sns_topic" "primary" {
  provider = aws.primary
  name     = "primary-${var.environment}-topic"

  tags = {
    Name        = "Primary Region Topic"
    Environment = var.environment
    Region      = var.primary_region
  }
}

# SNS Topic in secondary region
resource "aws_sns_topic" "secondary" {
  provider = aws.secondary
  name     = "secondary-${var.environment}-topic"

  tags = {
    Name        = "Secondary Region Topic"
    Environment = var.environment
    Region      = var.secondary_region
  }
}
```

### 6. Apply the Changes

Apply the configuration to create the SNS topics:
```bash
terraform apply
```

### 7. Create outputs.tf

Create an outputs.tf file:

```hcl
output "primary_bucket_name" {
  description = "Name of the S3 bucket in the primary region"
  value       = aws_s3_bucket.primary.bucket
}

output "secondary_bucket_name" {
  description = "Name of the S3 bucket in the secondary region"
  value       = aws_s3_bucket.secondary.bucket
}

output "primary_bucket_region" {
  description = "Region of the primary S3 bucket"
  value       = aws_s3_bucket.primary.region
}

output "secondary_bucket_region" {
  description = "Region of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.region
}

output "primary_sns_topic_arn" {
  description = "ARN of the SNS topic in the primary region"
  value       = aws_sns_topic.primary.arn
}

output "secondary_sns_topic_arn" {
  description = "ARN of the SNS topic in the secondary region"
  value       = aws_sns_topic.secondary.arn
}
```

### 8. Apply to See Outputs
```bash
terraform apply
```

### 9. Clean Up Resources

When you're done, clean up all resources:
```bash
terraform destroy
```

## Understanding Multiple Provider Configuration

### Provider Aliases
- Provider aliases allow you to define multiple configurations for the same provider
- Each provider block can have its own configuration (region, credentials, etc.)
- Use the `alias` attribute to name each provider configuration

### Specifying Providers for Resources
- Use the `provider` attribute in resource blocks to specify which provider to use
- Format is `provider = aws.<alias>`
- If no provider is specified, the default provider (without an alias) is used

### Common Multi-Region Scenarios
- Disaster recovery across regions
- Deploying to multiple regions for reduced latency
- Creating resources that interact across regions

## Additional Exercises

1. Add a DynamoDB table to each region
2. Create a CloudWatch Log Group in each region
3. Create resources in a third region using an additional provider block