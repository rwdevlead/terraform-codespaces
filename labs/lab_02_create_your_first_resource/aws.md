# LAB-02-AWS: Creating Your First AWS Resource with Terraform

## Overview
In this lab, you will create your first AWS resource using Terraform: a Virtual Private Cloud (VPC). You'll configure AWS credentials using environment variables and create a basic VPC with a CIDR block. This lab introduces resource blocks, basic attribute configurations, and the complete Terraform workflow including planning and applying changes.

## Prerequisites
- Terraform installed
- AWS CLI installed
- AWS account with appropriate permissions
- Completion of LAB-01-AWS

## Estimated Time
20 minutes

## Lab Steps

### 1. Configure AWS Credentials

Set your AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Create Project Structure

Create a new directory for this lab:

```bash
mkdir terraform-lab-02-aws
cd terraform-lab-02-aws
```

### 3. Create Configuration Files

Create the necessary Terraform configuration files:

```bash
touch main.tf providers.tf variables.tf
```

### 4. Configure the AWS Provider

In `providers.tf`, add your provider configuration:

```hcl
terraform {
  required_version = ">= 1.10.x"  # Replace with your installed version
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

### 5. Create Your First Resource

In `main.tf`, add the following configuration to create a VPC:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "Lab"
    Managed_By  = "Terraform"
  }
}
```

### 6. Format and Validate

Format your configuration:
```bash
terraform fmt
```

Validate the syntax:
```bash
terraform init
terraform validate
```

### 7. Review the Plan

Generate and review the execution plan:
```bash
terraform plan
```

Examine the plan output to understand what Terraform will create. You should see that Terraform plans to:
- Create a new VPC with the specified CIDR block
- Enable DNS support features
- Add the specified tags

### 8. Apply the Configuration

Apply the configuration to create the resource:
```bash
terraform apply
```

Type 'yes' when prompted to confirm the action.

### 9. Verify the Resource

Verify the VPC was created using the AWS CLI:
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main-vpc"
```

## Verification Steps

After completing the lab, verify your work by confirming:
1. The VPC exists in your AWS account
2. The CIDR block is set to 10.0.0.0/16
3. DNS hostnames and DNS support are enabled
4. The tags are properly applied
5. The state file contains your resource details

## Clean Up

Remove the created resources:
```bash
terraform destroy
```

Type 'yes' when prompted to confirm the deletion.

## Success Criteria
- AWS credentials are properly configured using environment variables
- The VPC is successfully created with the specified configuration
- All Terraform commands (init, plan, apply) execute without errors
- The resource is properly tagged
- The resource is successfully destroyed during cleanup

## Additional Challenge
Try modifying the VPC's CIDR block or tags and run another `terraform plan` and `apply` to see how Terraform handles changes to existing resources.

## Common Issues and Solutions

1. Credential Issues
   - Ensure environment variables are properly set
   - Verify AWS CLI configuration
   - Check for typos in access keys

2. Permission Issues
   - Ensure your AWS user has EC2 and VPC permissions
   - Verify region settings match your credentials

3. CIDR Block Conflicts
   - Ensure the CIDR block doesn't overlap with existing VPCs
   - Verify the CIDR block is valid

## Learn More
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [Terraform AWS VPC Resource Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)