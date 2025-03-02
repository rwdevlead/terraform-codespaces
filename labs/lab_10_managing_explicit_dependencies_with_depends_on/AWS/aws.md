# LAB-10-AWS: Managing Explicit Dependencies with depends_on

## Overview
This lab demonstrates how to use Terraform's `depends_on` meta-argument with AWS resources. You'll learn when to use explicit dependencies versus relying on implicit dependencies, using only free AWS resources.

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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
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
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-vpc"
    Environment = var.environment
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr
  availability_zone = "${var.region}a"

  tags = {
    Name        = "public-subnet"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-igw"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "public-route-table"
    Environment = var.environment
  }
}

# S3 Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "logs-${random_string.suffix.result}"

  tags = {
    Name        = "logs-bucket"
    Environment = var.environment
  }
}
```

## Lab Steps

### 1. Identify Implicit Dependencies

Examine the main.tf file and identify the implicit dependencies:
- Subnet depends on VPC (via vpc_id)
- Internet Gateway depends on VPC (via vpc_id)
- Route Table depends on VPC (via vpc_id) and Internet Gateway (via gateway_id)
- S3 Bucket implicitly depends on the random_string resource

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

### 4. Add Resources with Potential Dependency Issues

Add the following resources to main.tf:

```hcl
# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "web-sg"
    Environment = var.environment
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "logs_policy" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Principal = "*"
      }
    ]
  })
}
```

### 5. Apply the Changes

Run Terraform apply again:
```bash
terraform apply
```

### 6. Add Resources with Explicit Dependencies

Now, add the following resources that require explicit dependencies:

```hcl
# Security Group Rule with explicit dependency
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  
  # Explicitly depend on the route table association to ensure
  # network routing is set up before allowing traffic
  depends_on = [aws_route_table_association.public]
}

# S3 Bucket Versioning with explicit dependency
resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
  
  # Explicitly depend on the bucket policy
  # This ensures the policy is fully applied before enabling versioning
  depends_on = [aws_s3_bucket_policy.logs_policy]
}

# S3 Bucket Logging configuration
resource "aws_s3_bucket_logging" "logs_logging" {
  bucket = aws_s3_bucket.logs.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "log/"
  
  # Explicitly depend on bucket versioning
  # This creates a chain of dependencies: policy -> versioning -> logging
  depends_on = [aws_s3_bucket_versioning.logs_versioning]
}
```

### 7. Apply and Observe Order
```bash
terraform apply
```

Watch how Terraform respects both your implicit and explicit dependencies.

### 8. Add Outputs

Create an outputs.tf file:

```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.bucket
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "dependency_example" {
  description = "Example of dependencies in this lab"
  value = {
    "Implicit dependencies" = "VPC -> Subnet, VPC -> IGW, IGW -> Route Table"
    "Explicit dependencies" = "Route Table Association -> SG Rule, Bucket Policy -> Versioning -> Logging"
  }
}
```

### 9. Apply to See Outputs
```bash
terraform apply
```

### 10. Clean Up Resources

When you're done, clean up all resources:
```bash
terraform destroy
```

## Understanding depends_on

### When to Use depends_on:
1. When there's no implicit dependency (no reference to another resource's attributes)
2. When a resource needs to be created after another, even though they don't directly reference each other
3. When you need to ensure a specific creation order for resources

### Examples in AWS:
- S3 bucket configurations that should be applied in a specific order
- Security group rules that depend on network routing being established
- IAM policies that reference resources by ARN but need those resources to be fully created first

### Syntax:
```hcl
resource "aws_example" "example" {
  # ... configuration ...
  
  depends_on = [
    aws_other_resource.name
  ]
}
```

## Additional Exercises

1. Add an S3 bucket lifecycle policy that depends on the bucket versioning
2. Create a chain of three related security group rules that depend on each other
3. Try adding a circular dependency and observe Terraform's error message