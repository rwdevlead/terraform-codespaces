# LAB-11-GH: Deploying Resources to Multiple Organizations

## Overview
This lab demonstrates how to use multiple provider blocks in Terraform to deploy GitHub resources to different organizations or user accounts simultaneously. You'll create resources under two different GitHub owners using a simple configuration.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- Multiple GitHub accounts or organizations
- GitHub personal access tokens for each account
- Basic understanding of Terraform and GitHub concepts

Note: GitHub credentials are required for this lab.

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
variable "primary_owner" {
  description = "Primary GitHub owner (organization or username)"
  type        = string
  default     = "your-primary-account"  # Replace with your primary GitHub username or organization
}

variable "secondary_owner" {
  description = "Secondary GitHub owner (organization or username)"
  type        = string
  default     = "your-secondary-account"  # Replace with your secondary GitHub username or organization
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "repo_visibility" {
  description = "Repository visibility"
  type        = string
  default     = "private"
}
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Primary owner provider
provider "github" {
  owner = var.primary_owner
  alias = "primary"
}

# Secondary owner provider
provider "github" {
  owner = var.secondary_owner
  alias = "secondary"
}
```

### main.tf
```hcl
# Repository for primary owner
resource "github_repository" "primary" {
  provider    = github.primary
  name        = "terraform-${var.environment}-primary"
  description = "Terraform managed repository for ${var.environment} environment"
  visibility  = var.repo_visibility
  auto_init   = true

  topics = ["terraform", "multi-provider-demo"]
}

# Repository for secondary owner
resource "github_repository" "secondary" {
  provider    = github.secondary
  name        = "terraform-${var.environment}-secondary"
  description = "Terraform managed repository for ${var.environment} environment"
  visibility  = var.repo_visibility
  auto_init   = true

  topics = ["terraform", "multi-provider-demo"]
}
```

## Lab Steps

### 1. Initialize Terraform

Set up your GitHub tokens as environment variables:
```bash
export GITHUB_TOKEN="your-primary-account-token"
export GITHUB_SECONDARY_TOKEN="your-secondary-account-token"
```

Configure the .terraformrc file to support multiple tokens:
```bash
cat > ~/.terraformrc << EOF
credentials "github.com" {
  token = "$GITHUB_TOKEN"
}
credentials "secondary.github.com" {
  token = "$GITHUB_SECONDARY_TOKEN"
}
EOF
```

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
- `provider = github.primary` for resources in the primary account
- `provider = github.secondary` for resources in the secondary account

### 4. Run Plan and Apply

Create the repositories in both accounts:
```bash
terraform plan
terraform apply
```

### 5. Add README Files to Each Repository

Add the following resources to main.tf:

```hcl
# README file for primary repository
resource "github_repository_file" "primary_readme" {
  provider          = github.primary
  repository        = github_repository.primary.name
  branch            = "main"
  file              = "README.md"
  content           = "# Primary Repository\n\nManaged by Terraform using multiple providers."
  commit_message    = "Add README"
  commit_author     = "Terraform"
  commit_email      = "terraform@example.com"
  overwrite_on_create = true
}

# README file for secondary repository
resource "github_repository_file" "secondary_readme" {
  provider          = github.secondary
  repository        = github_repository.secondary.name
  branch            = "main"
  file              = "README.md"
  content           = "# Secondary Repository\n\nManaged by Terraform using multiple providers."
  commit_message    = "Add README"
  commit_author     = "Terraform"
  commit_email      = "terraform@example.com"
  overwrite_on_create = true
}
```

### 6. Apply the Changes

Apply the configuration to create the README files:
```bash
terraform apply
```

### 7. Create outputs.tf

Create an outputs.tf file:

```hcl
output "primary_repository_url" {
  description = "URL of the repository in the primary account"
  value       = github_repository.primary.html_url
}

output "secondary_repository_url" {
  description = "URL of the repository in the secondary account"
  value       = github_repository.secondary.html_url
}

output "primary_owner" {
  description = "Primary GitHub owner"
  value       = var.primary_owner
}

output "secondary_owner" {
  description = "Secondary GitHub owner"
  value       = var.secondary_owner
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
- Each provider block can have its own configuration (owner, tokens, etc.)
- Use the `alias` attribute to name each provider configuration

### Specifying Providers for Resources
- Use the `provider` attribute in resource blocks to specify which provider to use
- Format is `provider = github.<alias>`
- If no provider is specified, the default provider (without an alias) is used

### Authentication with Multiple GitHub Accounts
- Each provider configuration can use different authentication tokens
- For automated workflows, you'll need to manage multiple GitHub tokens
- For local development, you can use the .terraformrc file to manage credentials