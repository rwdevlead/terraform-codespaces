# LAB-16-GITHUB: Replacing and Removing Resources in Terraform

## Overview
In this lab, you will learn how to replace and remove resources in Terraform when working with GitHub. You'll practice using the `-replace` flag and removing resources from configuration using GitHub resources.

## Prerequisites
- Terraform installed (v1.0.0+)
- GitHub account
- GitHub personal access token with appropriate permissions

## Estimated Time
30 minutes

## Initial Configuration Files

Create the following files in your working directory:

### variables.tf
```hcl
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tflab16"
}

variable "repository_visibility" {
  description = "Repository visibility setting"
  type        = string
  default     = "private"
}

variable "repository_description" {
  description = "Description for the repository"
  type        = string
  default     = "Repository created for Terraform Lab 16"
}

variable "repository_topics" {
  description = "Topics for the repository"
  type        = list(string)
  default     = ["terraform", "lab", "example"]
}

variable "auto_init" {
  description = "Initialize repository with README"
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Template for gitignore file"
  type        = string
  default     = "Terraform"
}

variable "random_suffix_length" {
  description = "Length of random suffix for unique resource names"
  type        = number
  default     = 6
}

variable "special_chars_allowed" {
  description = "Allow special characters in random string"
  type        = bool
  default     = false
}

variable "upper_chars_allowed" {
  description = "Allow uppercase characters in random string"
  type        = bool
  default     = false
}
```

### main.tf
```hcl
# GitHub Repository
resource "github_repository" "example" {
  name        = "${var.prefix}-repo-${random_string.suffix.result}"
  description = var.repository_description
  visibility  = var.repository_visibility
  
  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  topics             = var.repository_topics
}

# GitHub Branch
resource "github_branch" "development" {
  repository = github_repository.example.name
  branch     = "development"
}

# Branch Protection
resource "github_branch_protection" "main" {
  repository_id = github_repository.example.node_id
  pattern       = "main"
  
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    required_approving_review_count = 1
  }
}

# Repository File
resource "github_repository_file" "readme" {
  repository          = github_repository.example.name
  branch              = "main"
  file                = "README.md"
  content             = "# ${github_repository.example.name}\n\n${var.repository_description}\n"
  commit_message      = "Update README"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Random string for resource name uniqueness
resource "random_string" "suffix" {
  length  = var.random_suffix_length
  special = var.special_chars_allowed
  upper   = var.upper_chars_allowed
}
```

### providers.tf
```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
```

### outputs.tf
```hcl
output "repository_name" {
  description = "Name of the created repository"
  value       = github_repository.example.name
}

output "repository_url" {
  description = "URL of the created repository"
  value       = github_repository.example.html_url
}

output "development_branch" {
  description = "Name of the development branch"
  value       = github_branch.development.branch
}
```

### terraform.tfvars.example
```hcl
# Copy this file to terraform.tfvars and update with your values
github_token = "your_personal_access_token_here"
github_owner = "your_github_username_or_organization_here"
```

## Lab Steps

### 1. Configure GitHub Token

Update the tfvars file with your GitHub information:

```bash
github_token = "<your_personal_access_token_here>"
github_owner = "<your_github_username_or_organization_here>"
```

### 2. Initialize and Apply
```bash
terraform init
terraform apply -auto-approve
```

### 3. Replace a Resource Using the `-replace` Flag

Let's replace the README file without changing its configuration:

```bash
terraform apply -replace="github_repository_file.readme" -auto-approve
```

Observe in the output how Terraform:
- Re-creates the file with the same content
- Note that with GitHub files, this results in a new commit

### 4. Replace a Resource by Modifying Configuration

Let's update the variables to change the repository's configuration. Create a file called `modified.tfvars`:

```hcl
prefix = "tflab16mod"
repository_description = "Modified repository for Terraform lab"
repository_topics = ["terraform", "lab", "modified", "example"]
```

Apply with the new variables:

```bash
terraform apply -var-file="modified.tfvars" -auto-approve
```

Observe how Terraform:
- Creates a new repository (since the name changes)
- Updates existing properties like description and topics

### 5. Remove a Resource by Deleting it from Configuration

Remove or comment out the branch protection resource from main.tf:

```hcl
# Branch Protection
# resource "github_branch_protection" "main" {
#   repository_id = github_repository.example.node_id
#   pattern       = "main"
#   
#   required_pull_request_reviews {
#     dismiss_stale_reviews           = true
#     required_approving_review_count = 1
#   }
# }
```

Apply the changes:

```bash
terraform apply -auto-approve
```

Observe that Terraform plans to remove the branch protection rule.

### 6. Remove a Resource Using `terraform destroy -target`

Now, let's remove the development branch using targeted destroy without changing the configuration:

```bash
terraform destroy -target=github_branch.development -auto-approve
```

Verify it's gone:

```bash
terraform state list
```

Run a normal apply to recreate it:

```bash
terraform apply -auto-approve
```

### 7. Clean Up

When finished, clean up all resources:

```bash
terraform destroy -auto-approve
```

## Key Concepts

### Resource Replacement Methods
- **Using `-replace` flag**: Forces resource recreation without configuration changes
- **Changing force-new attributes**: Some attribute changes automatically trigger replacement

### Resource Removal Methods
- **Removing from configuration**: Delete the resource block from your .tf files
- **Using `terraform destroy -target`**: Temporarily removes a resource; it will be recreated on next apply

## Additional Challenge

1. Add a GitHub team resource and provide it access to the repository, then practice replacing and removing it
2. Create a terraform.tfvars file that changes multiple variables at once, then observe which resources get replaced
3. Try adding webhook configurations to the repository and practice replacing them with different settings