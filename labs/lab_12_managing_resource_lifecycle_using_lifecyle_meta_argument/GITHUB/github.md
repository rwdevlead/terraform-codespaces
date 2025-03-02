# LAB-12-GH: Managing Resource Lifecycles with lifecycle Meta-Argument

## Overview
This lab demonstrates how to use Terraform's `lifecycle` meta-argument to control the creation, update, and deletion behavior of GitHub resources. You'll learn how to prevent resource destruction and ignore specific changes.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- GitHub account
- GitHub personal access token
- Basic understanding of Terraform and GitHub concepts

Note: GitHub credentials are required for this lab.

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
variable "github_owner" {
  description = "GitHub owner (organization or username)"
  type        = string
  default     = "your-github-username"  # Replace with your GitHub username or organization
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

provider "github" {
  owner = var.github_owner
}
```

### main.tf
```hcl
# Standard repository without lifecycle configuration
resource "github_repository" "standard" {
  name        = "standard-${var.environment}-repo"
  description = "Standard repository for ${var.environment} environment"
  visibility  = var.repo_visibility
  auto_init   = true

  topics = ["terraform", "lifecycle-demo"]
}

# Issue label without lifecycle configuration
resource "github_issue_label" "standard" {
  repository  = github_repository.standard.name
  name        = "standard"
  color       = "FF0000"
  description = "Standard issue label"
}
```

## Lab Steps

### 1. Initialize Terraform

Set up your GitHub token as an environment variable:
```bash
export GITHUB_TOKEN="your-personal-access-token"
```

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

Add a new repository with the `prevent_destroy` lifecycle configuration:

```hcl
# Repository with prevent_destroy
resource "github_repository" "protected" {
  name        = "protected-${var.environment}-repo"
  description = "Protected repository for ${var.environment} environment"
  visibility  = var.repo_visibility
  auto_init   = true

  topics = ["terraform", "lifecycle-demo", "protected"]

  lifecycle {
    prevent_destroy = true
  }
}
```

### 5. Apply the Changes

Apply the configuration to create the protected repository:
```bash
terraform apply
```

### 6. Try to Destroy the Protected Repository

Modify main.tf to comment out or remove the protected repository resource:

```hcl
# Repository with prevent_destroy
# resource "github_repository" "protected" {
#   name        = "protected-${var.environment}-repo"
#   description = "Protected repository for ${var.environment} environment"
#   visibility  = var.repo_visibility
#   auto_init   = true
#
#   topics = ["terraform", "lifecycle-demo", "protected"]
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

Terraform should prevent you from destroying the protected repository.

### 7. Restore the Protected Repository Resource

Uncomment or restore the protected repository resource in main.tf.

### 8. Add ignore_changes Lifecycle Configuration

Add a team with the `ignore_changes` lifecycle configuration to ignore specific attributes:

```hcl
# Team with ignore_changes
resource "github_team" "updates" {
  name        = "updates-${var.environment}"
  description = "Team with lifecycle updates configuration"
  privacy     = "closed"

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}
```

### 9. Apply to Create the Team
```bash
terraform apply
```

### 10. Update the Team Description

Let's simulate changing the description outside of Terraform by updating it in our Terraform configuration:

```hcl
# Team with ignore_changes
resource "github_team" "updates" {
  name        = "updates-${var.environment}"
  description = "This description has been changed but will be ignored"
  privacy     = "closed"

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}
```

### 11. Apply and Observe Behavior
```bash
terraform plan
terraform apply
```

Notice that Terraform doesn't try to update the description since we've configured it to ignore changes to this attribute.

### 12. Add Repository Branch with ignore_changes for Branch Protection

Add a repository with a `default_branch` that shouldn't be changed if it's modified outside of Terraform:

```hcl
# Repository with branch ignore_changes
resource "github_repository" "branch_ignore" {
  name        = "branch-${var.environment}-repo"
  description = "Repository with branch ignore_changes configuration"
  visibility  = var.repo_visibility
  auto_init   = true
  
  # If branch was changed outside of Terraform, don't try to change it back
  lifecycle {
    ignore_changes = [
      default_branch
    ]
  }
}
```

### 13. Apply to Create the Repository
```bash
terraform apply
```

### 14. Create outputs.tf

Create an outputs.tf file:

```hcl
output "standard_repository_url" {
  description = "URL of the standard repository"
  value       = github_repository.standard.html_url
}

output "protected_repository_url" {
  description = "URL of the protected repository"
  value       = github_repository.protected.html_url
}

output "team_name" {
  description = "Name of the team with ignore_changes"
  value       = github_team.updates.name
}

output "branch_ignore_repository_url" {
  description = "URL of the repository with branch ignore_changes"
  value       = github_repository.branch_ignore.html_url
}

output "lifecycle_examples" {
  description = "Examples of lifecycle configurations used"
  value = {
    "prevent_destroy" = "Repository protected from accidental deletion"
    "ignore_changes" = "Team description and repository branch changes are ignored"
  }
}
```

### 15. Apply to See Outputs
```bash
terraform apply
```

### 16. Clean Up Resources

When you're done, remove the `prevent_destroy` lifecycle setting from the protected repository first:

```hcl
# Repository with prevent_destroy removed
resource "github_repository" "protected" {
  name        = "protected-${var.environment}-repo"
  description = "Protected repository for ${var.environment} environment"
  visibility  = var.repo_visibility
  auto_init   = true

  topics = ["terraform", "lifecycle-demo", "protected"]

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
- Useful for protecting critical resources like important repositories
- Must be removed before you can destroy the resource

### ignore_changes
- Tells Terraform to ignore changes to specific attributes
- Useful when attributes are modified outside of Terraform
- Can be applied to specific attributes or all attributes with `ignore_changes = all`

### create_before_destroy
- This property is less commonly used with GitHub resources as most GitHub resources can't exist in parallel with the same name
- More useful for infrastructure resources that support parallel deployment

### Syntax:
```hcl
resource "github_example" "example" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      description,
      attribute_name
    ]
  }
}
```

## Common GitHub Use Cases

1. **Protecting Key Repositories**
   - Use `prevent_destroy` to prevent accidental deletion of important repositories

2. **Handling External Changes**
   - Use `ignore_changes` for repositories that might be modified by users outside of Terraform
   - Common for descriptions, wikis, branch protection rules

3. **Teams and Permissions**
   - Use `ignore_changes` for team memberships that might be managed manually
   - Useful for repositories where permissions change frequently