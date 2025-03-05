# LAB-12-AWS: Managing Resource Lifecycles with lifecycle Meta-Argument

## Overview
This lab demonstrates how to use Terraform's `lifecycle` meta-argument to control the creation, update, and deletion behavior of AWS resources. You'll learn how to prevent resource destruction, create resources before destroying old ones, and ignore specific changes.

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
15 minutes

## Existing Configuration Files

The lab directory contains the following initial files:

### variables.tf
```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}
```

### main.tf
```hcl
# Random string for uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket without lifecycle configuration
resource "aws_s3_bucket" "standard" {
  bucket = "standard-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Standard Bucket"
    Environment = var.environment
  }
}

# DynamoDB Table without lifecycle configuration
resource "aws_dynamodb_table" "standard" {
  name         = "standard-${var.environment}-${random_string.suffix.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    Name        = "Standard Table"
    Environment = var.environment
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

Add a new S3 bucket with the `prevent_destroy` lifecycle configuration:

```hcl
# S3 Bucket with prevent_destroy
resource "aws_s3_bucket" "protected" {
  bucket = "protected-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Protected Bucket"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

### 5. Apply the Changes

Apply the configuration to create the protected S3 bucket:
```bash
terraform apply
```

### 6. Try to Destroy the Protected Bucket

Modify main.tf to comment out or remove the protected bucket resource:

```hcl
# S3 Bucket with prevent_destroy
# resource "aws_s3_bucket" "protected" {
#   bucket = "protected-${var.environment}-${random_string.suffix.result}"
#
#   tags = {
#     Name        = "Protected Bucket"
#     Environment = var.environment
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

Terraform should prevent you from destroying the protected bucket.

### 7. Restore the Protected Bucket Resource

Uncomment or restore the protected bucket resource in main.tf.

### 8. Add create_before_destroy Lifecycle Configuration

Add a DynamoDB table with the `create_before_destroy` lifecycle configuration:

```hcl
# DynamoDB Table with create_before_destroy
resource "aws_dynamodb_table" "replacement" {
  name         = "replacement-${var.environment}-${random_string.suffix.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  tags = {
    Name        = "Replacement Table"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### 9. Apply to Create the Replacement Table
```bash
terraform apply
```

### 10. Add ignore_changes Lifecycle Configuration

Add an SNS topic with the `ignore_changes` lifecycle configuration to ignore specific attributes:

```hcl
# SNS Topic with ignore_changes
resource "aws_sns_topic" "updates" {
  name = "updates-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Updates Topic"
    Environment = var.environment
    Version     = "1.0.0"  # This will be ignored
  }

  lifecycle {
    ignore_changes = [
      tags["Version"]
    ]
  }
}
```

### 11. Apply to Create the SNS Topic
```bash
terraform apply
```

### 12. Update the Version Tag Outside of Terraform

Let's simulate changing the Version tag outside of Terraform (e.g., via AWS Console) by updating it in our Terraform configuration:

```hcl
# SNS Topic with ignore_changes
resource "aws_sns_topic" "updates" {
  name = "updates-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Updates Topic"
    Environment = var.environment
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
output "standard_bucket_name" {
  description = "Name of the standard S3 bucket"
  value       = aws_s3_bucket.standard.bucket
}

output "protected_bucket_name" {
  description = "Name of the protected S3 bucket"
  value       = aws_s3_bucket.protected.bucket
}

output "standard_dynamodb_name" {
  description = "Name of the standard DynamoDB table"
  value       = aws_dynamodb_table.standard.name
}

output "replacement_dynamodb_name" {
  description = "Name of the replacement DynamoDB table"
  value       = aws_dynamodb_table.replacement.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.updates.arn
}

output "lifecycle_examples" {
  description = "Examples of lifecycle configurations used"
  value = {
    "prevent_destroy"      = "S3 bucket protected from accidental deletion"
    "create_before_destroy" = "DynamoDB table created before replacing"
    "ignore_changes"       = "SNS Topic ignores changes to Version tag"
  }
}
```

### 15. Apply to See Outputs
```bash
terraform apply
```

### 16. Clean Up Resources

When you're done, remove the `prevent_destroy` lifecycle setting from the protected bucket first:

```hcl
# S3 Bucket with prevent_destroy removed
resource "aws_s3_bucket" "protected" {
  bucket = "protected-${var.environment}-${random_string.suffix.result}"

  tags = {
    Name        = "Protected Bucket"
    Environment = var.environment
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
resource "aws_example" "example" {
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

## Additional Exercises

1. Experiment with using `ignore_changes = all` on a resource
2. Create a resource with multiple lifecycle settings
3. Try creating a resource that requires replacement when certain attributes change