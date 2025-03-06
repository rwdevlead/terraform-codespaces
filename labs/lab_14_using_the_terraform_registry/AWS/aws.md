# LAB-14-AWS: Using Terraform Registry Modules

## Overview
In this lab, you will learn how to use modules from the Terraform Registry to create infrastructure more efficiently. You'll use two different modules, with one module using the output from another. You'll also call the same module multiple times with different parameters to create similar but unique resources. The lab uses AWS free-tier resources to ensure no costs are incurred.

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
25 minutes

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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "main-vpc"
}

variable "s3_buckets" {
  description = "Map of S3 buckets to create"
  type        = map(string)
  default = {
    "logs"      = "Stores application logs"
    "artifacts" = "Stores build artifacts"
    "configs"   = "Stores application configs"
  }
}
```

## Lab Steps

### 1. Configure AWS Credentials

Set up your AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

### 2. Use the VPC Module from Terraform Registry

Create a `main.tf` file and use the AWS VPC module:

```hcl
# Module 1: VPC Module from Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.environment}-${var.vpc_name}"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}
```

### 3. Use the Security Group Module with VPC Output

Add the AWS Security Group module, using the VPC ID output from the VPC module:

```hcl
# Module 2: Security Group Module from Terraform Registry
# This module uses the VPC ID output from the VPC module
module "security_group_web" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.environment}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id  # Using output from the VPC module

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Role        = "web"
  }
}
```

### 4. Call the Security Group Module a Second Time

Call the security group module again with different parameters to create another security group:

```hcl
# Call the Security Group module a second time to create a different security group
module "security_group_app" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = module.vpc.vpc_id  # Using output from the VPC module

  ingress_cidr_blocks = [var.vpc_cidr]  # Only allow traffic from within the VPC
  ingress_rules       = ["ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Application port"
      cidr_blocks = var.vpc_cidr
    }
  ]
  egress_rules = ["all-all"]

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Role        = "app"
  }
}
```

### 5. Use Module with For_Each

Now, let's demonstrate how to use the `for_each` meta-argument with a module. Add the following to your `main.tf` file to create multiple S3 buckets using the same module but with different names and descriptions:

```hcl
# Module 3: Using S3 bucket module with for_each
module "s3_buckets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  for_each = var.s3_buckets

  bucket = "${var.environment}-${each.key}-bucket"
  acl    = "private"

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Purpose     = each.value
    Name        = "${var.environment}-${each.key}-bucket"
  }
}
```

This configuration:
- Uses the AWS S3 bucket module from the Terraform Registry
- Creates a bucket for each key-value pair in the `s3_buckets` variable
- Uses the key to name each bucket (with environment prefix)
- Uses the value as the description in the tags
- Configures each bucket with proper security settings

Create an `outputs.tf` file to output important information:

```hcl
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "web_security_group_id" {
  description = "The ID of the web security group"
  value       = module.security_group_web.security_group_id
}

output "app_security_group_id" {
  description = "The ID of the app security group"
  value       = module.security_group_app.security_group_id
}

output "s3_bucket_names" {
  description = "The names of the created S3 buckets"
  value       = { for k, v in module.s3_buckets : k => v.s3_bucket_id }
}
```

### 6. Add Outputs

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Notice how Terraform:
- Downloads the modules from the Terraform Registry
- Creates a VPC with public and private subnets using the VPC module
- Creates two different security groups using the same module with different parameters
- Successfully references the VPC ID from the first module output

### 7. Initialize and Apply

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Notice how Terraform:
- Downloads the modules from the Terraform Registry
- Creates a VPC with public and private subnets using the VPC module
- Creates two different security groups using the same module with different parameters
- Creates multiple S3 buckets by using the same module with for_each
- Successfully references the VPC ID from the first module output

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
source = "terraform-aws-modules/vpc/aws"
```
This format (`<NAMESPACE>/<NAME>/<PROVIDER>`) refers to modules in the public Terraform Registry.

### Module Versioning
The `version` attribute pins the module to a specific version:
```
version = "5.1.2"
```
This ensures consistent behavior even if the module is updated in the registry.

### Module Inputs
Each module accepts input variables that control its behavior:
```
name = "${var.environment}-${var.vpc_name}"
cidr = var.vpc_cidr
```

### Module Outputs
Modules provide outputs that can be used by other resources:
```
vpc_id = module.vpc.vpc_id
```
Here, the VPC ID output from the first module is used as an input for the second module.

### Multiple Module Instances
The same module can be called multiple times with different parameters:
```
module "security_group_web" {
  name = "${var.environment}-web-sg"
  ...
}

module "security_group_app" {
  name = "${var.environment}-app-sg"
  ...
}
```

### Using For_Each with Modules
Modules can be instantiated multiple times using for_each:
```
module "s3_buckets" {
  for_each = var.s3_buckets
  bucket = "${var.environment}-${each.key}-bucket"
  ...
}
```
This creates one module instance for each element in the map, with each instance receiving different input values.

## Additional Resources

- [Terraform Registry](https://registry.terraform.io/)
- [AWS VPC Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS Security Group Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest)