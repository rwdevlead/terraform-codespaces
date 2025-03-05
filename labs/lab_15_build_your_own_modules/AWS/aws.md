# LAB-15-AWS: Creating and Using Local Modules

## Overview
In this lab, you will create your own local Terraform modules and use them to build AWS IAM resources. You'll create two modules - one for IAM policies and one for IAM roles - and then call these modules from a parent configuration. This lab teaches you how to build reusable modules, pass variables between modules, and organize your Terraform code efficiently. All resources created in this lab are part of the AWS free tier.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- AWS free tier account
- Basic understanding of Terraform and AWS IAM concepts

Note: AWS credentials are required for this lab.

## Estimated Time
40 minutes

## Lab Steps

### 1. Configure AWS Credentials

Set up your AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

### 2. Create the Directory Structure

Create the following directory structure for your project:

```bash
mkdir -p modules/iam_policy
mkdir -p modules/iam_role
```

Alternatively, you can create these directories and files using the VSCode UI if you prefer:
- Right-click in the Explorer panel and select "**New Folder**" to create the "**modules**" directory
- Right-click on "**modules**" and create the "**iam_policy**" and "**iam_role**" subdirectories
- Right-click in the main directory and select "**New File**" to create each of the `.tf` files

### 3. Create the Providers File

Add the following content to `providers.tf` if it doesn't already exist:

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

### 4. Create the Variables File

Add the following content to `variables.tf`:

```hcl
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```
```

### 5. Create the IAM Policy Module

Create the following files in the `modules/iam_policy` directory:

#### a. Create `modules/iam_policy/variables.tf`:

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM policy"
  type        = string
}

variable "policy_description" {
  description = "Description of the IAM policy"
  type        = string
}

variable "policy_statements" {
  description = "List of policy statements"
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
}
```

#### b. Create `modules/iam_policy/main.tf`:

```hcl
resource "aws_iam_policy" "policy" {
  name        = "${var.environment}-${var.policy_name}"
  path        = "/"
  description = var.policy_description
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.policy_statements : {
        Effect    = statement.effect
        Action    = statement.actions
        Resource  = statement.resources
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

#### c. Create `modules/iam_policy/outputs.tf`:

```hcl
output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.policy.arn
}

output "policy_name" {
  description = "Name of the IAM policy"
  value       = aws_iam_policy.policy.name
}

output "policy_id" {
  description = "ID of the IAM policy"
  value       = aws_iam_policy.policy.id
}
```

### 6. Create the IAM Role Module

Create the following files in the `modules/iam_role` directory:

#### a. Create `modules/iam_role/variables.tf`:

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
}

variable "trusted_principal" {
  description = "AWS service principal that can assume this role"
  type        = string
}

variable "policy_arns" {
  description = "List of policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}
```

#### b. Create `modules/iam_role/main.tf`:

```hcl
resource "aws_iam_role" "role" {
  name        = "${var.environment}-${var.role_name}"
  description = var.role_description
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = var.trusted_principal
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.role.name
  policy_arn = var.policy_arns[count.index]
}
```

#### c. Create `modules/iam_role/outputs.tf`:

```hcl
output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.role.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.role.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.role.id
}
```

### 7. Create the Main Configuration

Add the following content to `main.tf` to use your local modules:

```hcl
# Create IAM policies using the iam_policy module directly, without variables
module "s3_read_only_policy" {
  source             = "./modules/iam_policy"
  environment        = var.environment
  policy_name        = "s3-read-only"
  policy_description = "Allow read-only access to S3"
  policy_statements  = [
    {
      effect    = "Allow"
      actions   = ["s3:Get*", "s3:List*"]
      resources = ["*"]
    }
  ]
}

module "cloudwatch_write_policy" {
  source             = "./modules/iam_policy"
  environment        = var.environment
  policy_name        = "cloudwatch-write"
  policy_description = "Allow CloudWatch write access"
  policy_statements  = [
    {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      resources = ["*"]
    }
  ]
}

# Create IAM roles and associate with policies
module "app_role" {
  source            = "./modules/iam_role"
  environment       = var.environment
  role_name         = "app-role"
  role_description  = "Application role"
  trusted_principal = "ec2.amazonaws.com"
  policy_arns       = [module.s3_read_only_policy.policy_arn]
}

module "monitoring_role" {
  source            = "./modules/iam_role"
  environment       = var.environment
  role_name         = "monitoring-role"
  role_description  = "Monitoring role"
  trusted_principal = "lambda.amazonaws.com"
  policy_arns       = [module.cloudwatch_write_policy.policy_arn]
}
```

### 8. Create the Outputs File

Add the following content to `outputs.tf`:

```hcl
output "policy_arns" {
  description = "ARNs of the created IAM policies"
  value = {
    s3_read_only = module.s3_read_only_policy.policy_arn,
    cloudwatch_write = module.cloudwatch_write_policy.policy_arn
  }
}

output "role_arns" {
  description = "ARNs of the created IAM roles"
  value = {
    app_role = module.app_role.role_arn,
    monitoring_role = module.monitoring_role.role_arn
  }
}

output "role_names" {
  description = "Names of the created IAM roles"
  value = {
    app_role = module.app_role.role_name,
    monitoring_role = module.monitoring_role.role_name
  }
}
```

### 9. Initialize and Apply

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Watch how Terraform:
- Processes each local module
- Creates the IAM policies using the policy module
- Creates the IAM roles using the role module
- Attaches the appropriate policies to each role

### 10. Modify a Module to See Changes

Let's modify the IAM policy module to add some additional tags. 

Update `modules/iam_policy/main.tf`:

```hcl
resource "aws_iam_policy" "policy" {
  name        = "${var.environment}-${var.policy_name}"
  path        = "/"
  description = var.policy_description
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in var.policy_statements : {
        Effect    = statement.effect
        Action    = statement.actions
        Resource  = statement.resources
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "iam_policy"
    Name        = "${var.environment}-${var.policy_name}"
  }
}
```

Apply the changes:

```bash
terraform apply
```

Notice how Terraform detects the changes in the module and updates only the affected resources.

### 11. Clean Up

Remove all created resources:

```bash
terraform destroy
```

## Understanding Local Modules

Let's examine the key aspects of creating and using local modules:

### Module Structure
A well-structured module typically contains:
- `main.tf` - The main resource definitions
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output definitions

### Module Source
For local modules, the source is a relative path:
```
source = "./modules/iam_policy"
```

### Module Inputs
Modules receive input through variables:
```
module "policies" {
  policy_name = each.key
  ...
}
```

### Module Outputs
Modules provide outputs that can be referenced:
```
module.policies["s3-read-only"].policy_arn
```

### Module Reuse
The same module can be used multiple times:
```
module "policies" {
  for_each = var.policies
  ...
}
```

## Benefits of Using Local Modules

1. **Code Reusability**: Write once, use multiple times
2. **Encapsulation**: Hide complex logic within modules
3. **Maintainability**: Change the module in one place, effects apply everywhere
4. **Organization**: Structured approach to managing resources
5. **Testing**: Modules can be tested independently
6. **Composability**: Combine modules to create complex architectures

## Additional Exercises

1. Add another policy type to the `policies` variable
2. Modify the role module to support custom inline policies
3. Create a third module for IAM users and have it use the policies module
4. Add conditional creation of resources within the modules