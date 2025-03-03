# LAB-13-GH: Using Basic Terraform Functions

## Overview
In this lab, you will learn how to use a few essential Terraform built-in functions: `min`, `max`, `join`, and `toset`. These functions help you manipulate values and create more flexible infrastructure configurations. The lab uses GitHub free resources to ensure no costs are incurred.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- GitHub account
- GitHub personal access token
- Basic understanding of Terraform and GitHub concepts

Note: GitHub credentials are required for this lab.

## Estimated Time
20 minutes

## Initial Configuration Files

### providers.tf
```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
  }
}

provider "github" {
  owner = var.organization
}
```

### variables.tf
```hcl
variable "organization" {
  description = "GitHub organization name"
  type        = string
  default     = "your-organization"  # Replace with your org name or username
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "repository_names" {
  description = "List of repository name suffixes"
  type        = list(string)
  default     = ["api", "web", "docs", "utils", "cli"]
}

variable "team_members" {
  description = "List of team members with duplicates"
  type        = list(string)
  default     = ["user1", "user2", "user3", "user1", "user4"]
}

variable "topics" {
  description = "List of repository topics"
  type        = list(string)
  default     = ["terraform", "infrastructure", "devops", "automation"]
}
```

## Lab Steps

### 1. Configure GitHub Credentials

Set up your GitHub personal access token:

```bash
export GITHUB_TOKEN="your_personal_access_token"
```

### 2. Create Repositories with Join Function

Create a `main.tf` file with repository resources using the join function:

```hcl
# Use join function to create repository names
resource "github_repository" "main" {
  count       = min(3, length(var.repository_names))
  name        = join("-", [var.environment, var.repository_names[count.index]])
  description = "Repository for ${var.repository_names[count.index]}"
  visibility  = "private"
  auto_init   = true

  # This creates repos like "dev-api", "dev-web", etc. using the join function
}
```

### 3. Use Min Function for Repository Count

The code above already uses the min function to limit the number of repositories to create:
```hcl
count = min(3, length(var.repository_names))
```

This ensures that no more than 3 repositories are created, even if the variable contains more names.

### 4. Use Toset Function to Remove Duplicates

Create a team with unique members:

```hcl
# Use toset function to remove duplicates from team members list
locals {
  unique_members = toset(var.team_members)
}

# Create a team
resource "github_team" "example" {
  name        = join("-", [var.environment, "team"])
  description = "Team with ${length(local.unique_members)} unique members"
  privacy     = "closed"
}
```

### 5. Create Repository Topics with Join

Create repository topics by joining arrays:

```hcl
# Use join for topic descriptions
resource "github_repository_file" "readme" {
  count              = min(3, length(var.repository_names))
  repository         = github_repository.main[count.index].name
  branch             = "main"
  file               = "README.md"
  content            = <<-EOT
    # ${upper(var.repository_names[count.index])}
    
    This is the ${var.repository_names[count.index]} repository.
    
    Topics: ${join(", ", var.topics)}
  EOT
  commit_message     = "Add README with topics"
  commit_author      = "Terraform"
  commit_email       = "terraform@example.com"
  overwrite_on_create = true
}
```

### 6. Add Simple Outputs

Create an `outputs.tf` file with a few outputs:

```hcl
output "repository_urls" {
  description = "URLs of the created repositories"
  value       = github_repository.main[*].html_url
}

output "repository_count" {
  description = "Number of repositories created (using min function)"
  value       = min(3, length(var.repository_names))
}

output "unique_team_members" {
  description = "List of unique team members (using toset function)"
  value       = local.unique_members
}

output "team_name" {
  description = "Team name (created with join function)"
  value       = github_team.example.name
}
```

### 7. Apply the Configuration

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

### 8. Clean Up

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
Example: `join("-", ["dev", "api"])` produces `"dev-api"`

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
Example: `toset(["user1", "user2", "user1"])` produces `["user1", "user2"]`