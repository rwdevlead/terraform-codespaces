# LAB-05-GH: Working with State, Data Sources, and CLI Commands

## Overview
In this lab, you will learn how to work with Terraform state, use data sources to query GitHub information, and explore additional Terraform CLI commands. You'll create a development environment configuration, learn how to inspect and manage state, and properly clean up all resources. The lab introduces the concept of using data sources to make your configurations more dynamic and organization-aware.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- GitHub account with appropriate permissions
- Completion of LAB-04-GH with existing repository configuration

## Estimated Time
35 minutes

## Lab Steps

### 1. Explore Terraform CLI Commands

Let's start by exploring some useful Terraform CLI commands:

```bash
# View all available Terraform commands
terraform help

# Get specific help about state commands
terraform state help

# Show current state resources
terraform state list

# Show details about a specific resource
terraform state show github_repository.main
```

### 2. Create a Development Environment Directory

Create a new directory for a development environment configuration:

```bash
# Create development directory at the same level as your terraform directory
cd ..
mkdir development
cd development

# Create configuration files
touch main.tf variables.tf providers.tf outputs.tf
```

### 3. Add Data Source Configurations

In the new `development` environment's `main.tf`, add the following configuration to query GitHub information:

```hcl
# Get information about the current user
data "github_user" "current" {
  username = ""
}

# Get information about the organization
data "github_organization" "current" {
  name = var.organization_name
}

# Create repository using data source information
resource "github_repository" "development" {
  name        = "development-repo"
  description = "Development repository created by ${data.github_user.current.login}"
  visibility  = "private"

  template {
    owner      = data.github_organization.current.orgname
    repository = var.template_repository
  }

  topics = [
    "development",
    data.github_organization.current.orgname,
    "terraform-managed"
  ]
}

# Create a team with dynamic naming
resource "github_team" "development" {
  name        = "dev-team-${data.github_user.current.login}"
  description = "Development team created via Terraform"
  privacy     = "closed"
}
```

### 4. Add Variable Definitions

Create the variables in `variables.tf`:

```hcl
variable "organization_name" {
  description = "Name of the GitHub organization"
  type        = string
}

variable "template_repository" {
  description = "Name of the template repository to use"
  type        = string
  default     = "template-repo"
}
```

### 5. Add Provider Configuration

Configure the provider in `providers.tf`:

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.5.0"
    }
  }
}

provider "github" {
  owner = var.organization_name
}
```

### 6. Add Outputs

Create outputs in `outputs.tf`:

```hcl
output "user_token_scopes" {
  description = "The OAuth scopes granted to the current user's token"
  value       = data.github_user.current.token_scopes
  sensitive   = true
}

output "organization_id" {
  description = "The ID of the organization"
  value       = data.github_organization.current.id
  sensitive   = true
}

output "repository_url" {
  description = "URL of the development repository"
  value       = github_repository.development.html_url
}

output "team_name" {
  description = "Name of the created team"
  value       = github_team.development.name
}

output "combined_info" {
  description = "Combined user and organization information"
  value       = "${data.github_user.current.login}-${data.github_organization.current.orgname}"
  sensitive   = true
}
```

### 7. Initialize and Apply Test Configuration

Initialize and apply the test configuration:

```bash
terraform init
terraform plan
terraform apply
```

### 8. Explore State Commands

With resources created, explore state commands:

```bash
# List all resources in state
terraform state list

# Show details of the repository
terraform state show github_repository.development

# Show all outputs
terraform output

# Notice that sensitive outputs show as (sensitive)
# To view sensitive outputs, use the state show command:
terraform state show output.user_token_scopes
terraform state show output.organization_id

# Or use the -json flag with terraform output:
terraform output -json user_token_scopes
```

Notice how sensitive outputs are handled differently:
- Regular `terraform output` will show "(sensitive)" for these values
- Using `terraform state show` or `terraform output -json` allows you to view the actual values
- This helps protect sensitive information from being accidentally displayed in logs or terminal output

### 9. Clean Up All Resources

First, clean up the development environment:

```bash
# In development directory
terraform destroy
```

Then, clean up the main environment:

```bash
# Change to main terraform directory
cd ../terraform
terraform destroy
```

Review and confirm the destruction of resources in both environments.

## Understanding Data Sources

Data sources allow Terraform to query information from your GitHub organization and use it in your configurations. In this lab, we:
- Retrieved user information
- Got organization details
- Used dynamic naming based on data source values
- Protected sensitive information using the sensitive output flag

## Verification Steps

After creating resources:
1. Verify the repository and team are created with correct settings
2. Check that the user and organization information is correctly used
3. Confirm all outputs show the expected information, with sensitive values properly masked
4. Verify you can view sensitive values using state commands

After cleanup:
1. Verify all resources are destroyed in both environments
2. Check the GitHub web interface to confirm no resources remain
3. Ensure all state files are clean

## Success Criteria
Your lab is successful if:
- You can use various Terraform CLI commands
- Data sources successfully query GitHub information
- Resources are created with dynamic names using data source information
- You understand how to work with sensitive outputs
- All resources are properly destroyed
- You understand how to manage multiple configurations

## Additional Exercises
1. Query additional GitHub data sources
2. Create more complex repository configurations
3. Explore other Terraform CLI commands
4. Practice state commands with different resources
5. Add more sensitive outputs and practice viewing them

## Common Issues and Solutions

If you see errors:
- Verify GitHub token permissions
- Ensure you're in the correct directory
- Check that all resources are properly referenced
- Verify organization access
- Confirm proper syntax for viewing sensitive outputs

## Conclusion
This lab demonstrated how to work with multiple configurations, use data sources, manage sensitive outputs, and properly clean up resources. These skills are essential for managing more complex Terraform deployments and maintaining clean GitHub environments.