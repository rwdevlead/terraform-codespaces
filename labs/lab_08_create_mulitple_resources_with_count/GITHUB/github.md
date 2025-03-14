# LAB-08-GH: Creating Multiple Resources with the Count Meta-Argument

## Overview
In this lab, you will learn how to use Terraform's `count` meta-argument to create multiple similar resources efficiently. You'll start with a configuration that creates individual resources and refactor it to create multiple resources using count. The lab uses GitHub resources that are available with free GitHub accounts.

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
40 minutes

## Existing Configuration Files

The lab directory contains the following files with repetitive resource creation that we'll refactor using count:

### main.tf
```hcl
# Individual Repository Resources
resource "github_repository" "repo1" {
  name        = "example-repo-1"
  description = "Example repository 1"
  visibility  = "public"
  auto_init   = true

  topics = ["example", "terraform", "repo1"]
}

resource "github_repository" "repo2" {
  name        = "example-repo-2"
  description = "Example repository 2"
  visibility  = "public"
  auto_init   = true

  topics = ["example", "terraform", "repo2"]
}

resource "github_repository" "repo3" {
  name        = "example-repo-3"
  description = "Example repository 3"
  visibility  = "public"
  auto_init   = true

  topics = ["example", "terraform", "repo3"]
}

# Individual Branch Protection Resources
resource "github_branch_protection" "protection1" {
  repository_id = github_repository.repo1.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true
}

resource "github_branch_protection" "protection2" {
  repository_id = github_repository.repo2.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true
}

resource "github_branch_protection" "protection3" {
  repository_id = github_repository.repo3.node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true
}

# Individual Issue Label Resources
resource "github_issue_label" "bug1" {
  repository  = github_repository.repo1.name
  name        = "bug"
  color       = "FF0000"
  description = "Bug issues"
}

resource "github_issue_label" "feature1" {
  repository  = github_repository.repo1.name
  name        = "feature"
  color       = "00FF00"
  description = "Feature requests"
}

resource "github_issue_label" "bug2" {
  repository  = github_repository.repo2.name
  name        = "bug"
  color       = "FF0000"
  description = "Bug issues"
}

resource "github_issue_label" "feature2" {
  repository  = github_repository.repo2.name
  name        = "feature"
  color       = "00FF00"
  description = "Feature requests"
}
```

### variables.tf
```hcl
variable "organization" {
  description = "GitHub organization name"
  type        = string
  default     = "your-organization"  # Replace with your org name or username
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
  }
}

provider "github" {
  owner = var.organization
}
```

Examine these files and notice:
- Individual repository resources with similar configuration
- Repetitive branch protection rules
- Multiple issue labels with the same settings
- Redundant code that could be simplified

## Lab Steps

### 1. Configure GitHub Credentials

Set up your GitHub personal access token:

```bash
export GITHUB_TOKEN="your_personal_access_token"
```

### 2. Update Variables for Count

Modify `variables.tf` to include variables that will work with count:

```hcl
variable "organization" {
  description = "GitHub organization name"
  type        = string
  default     = "your-organization"  # Replace with your org name or username
}

variable "repo_count" {
  description = "Number of repositories to create"
  type        = number
  default     = 3
}

variable "repo_names" {
  description = "Names for repositories"
  type        = list(string)
  default     = ["example-repo-1", "example-repo-2", "example-repo-3"]
}

variable "label_repositories" {
  description = "Repositories to add labels to"
  type        = list(number)
  default     = [0, 1]  # Indexes of repos to add labels to
}

variable "label_names" {
  description = "Names for issue labels"
  type        = list(string)
  default     = ["bug", "feature"]
}

variable "label_colors" {
  description = "Colors for issue labels"
  type        = list(string)
  default     = ["FF0000", "00FF00"]
}

variable "label_descriptions" {
  description = "Descriptions for issue labels"
  type        = list(string)
  default     = ["Bug issues", "Feature requests"]
}
```

### 3. Refactor Repositories Using Count

Replace the individual repository resources with a single count-based resource in `main.tf`:

```hcl
# Refactored Repository Resources using count
resource "github_repository" "repo" {
  count       = var.repo_count
  name        = var.repo_names[count.index]
  description = "Example repository ${count.index + 1}"
  visibility  = "public"
  auto_init   = true

  topics = ["example", "terraform", "repo${count.index + 1}"]
}
```

### 4. Apply and Test Repository Count

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Verify that three repositories are created with the correct names and descriptions.

### 5. Adjust Repository Count

Modify the repo_count variable in `terraform.tfvars` (create this file) to test different repository counts:

```hcl
repo_count = 2
```

Apply the changes and observe the results:

```bash
terraform plan
terraform apply
```

Notice how Terraform plans to destroy one repository, maintaining only the number specified in the count.

### 6. Refactor Branch Protection Using Count

Next, replace the individual branch protection resources with a count-based approach:

```hcl
# Refactored Branch Protection resources using count
resource "github_branch_protection" "protection" {
  count         = var.repo_count
  repository_id = github_repository.repo[count.index].node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true
}
```

Apply the changes:

```bash
terraform plan
terraform apply
```

### 7. Refactor Issue Labels Using Nested Counts

For a more complex example, refactor the issue label resources using nested counts:

```hcl
# Refactored Issue Label Resources
resource "github_issue_label" "label" {
  count       = 4  # 2 labels for 2 repos = 4 labels
  repository  = github_repository.repo[count.index % 2].name  # Alternates between repo[0] and repo[1]
  name        = var.label_names[count.index / 2]  # First 2 are "bug", next 2 are "feature"
  color       = var.label_colors[count.index / 2]
  description = var.label_descriptions[count.index / 2]
}
```

### 8. Create Outputs Using Count

Create an `outputs.tf` file to demonstrate how to reference count-based resources:

```hcl
output "repository_urls" {
  description = "URLs of the created repositories"
  value       = github_repository.repo[*].html_url
}

output "repository_names" {
  description = "Names of the created repositories"
  value       = github_repository.repo[*].name
}

output "protection_repository_ids" {
  description = "IDs of repositories with branch protection"
  value       = github_branch_protection.protection[*].repository_id
}

output "label_repositories" {
  description = "Repositories with labels"
  value       = distinct(github_issue_label.label[*].repository)
}
```

### 9. Create README Files with Count

Add this to `variables.tf`:
```hcl
variable "readme_count" {
  description = "Number of README files to create"
  type        = number
  default     = 2
}
```

Add these repository files to `main.tf`:
```hcl
# Create multiple README files
resource "github_repository_file" "readme" {
  count               = var.readme_count
  repository          = github_repository.repo[count.index].name
  branch              = "main"
  file                = "README.md"
  content             = "# Repository ${count.index + 1}\nThis is an example repository created with Terraform count."
  commit_message      = "Add README"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}
```

Apply the configuration with different readme counts:

```bash
# Set readme_count to 1
terraform apply -var="readme_count=1"

# Set readme_count to 2
terraform apply -var="readme_count=2"
```

### 10. Clean Up

Remove all created resources:

```bash
terraform destroy
```

## Understanding Count

Let's examine how count improves your Terraform configurations:

### Basic Count Usage
- `count = N` creates N instances of a resource
- `count.index` provides the current index (0 to N-1)
- Each resource instance gets a unique index

### Resource References
- Individual resource: `github_repository.repo[0]`
- All resources: `github_repository.repo[*]`
- Specific attribute of all resources: `github_repository.repo[*].name`

### Count with Variables
- Using list variables with count.index
- Controlling count with number variables
- Creating related resources with similar counts

### Limitations
- Resources must be identical except for elements that use count.index
- Changing the count can cause resource recreation
- Removing an element from the middle of a list can affect multiple resources

## Additional Exercises

1. Create multiple teams using count
2. Create repository collaborators for each repository
3. Create webhooks for each repository
4. Add different labels to each repository based on its index

## Common Issues and Solutions

1. **Index Out of Range**
   - Ensure list variables have at least as many elements as the count value
   - Be careful when referencing list elements with count.index

2. **Resource Recreation**
   - Be cautious when changing count on existing infrastructure
   - Adding or removing elements can affect resource IDs

3. **Resource References**
   - Always use the [index] or [*] notation when referencing count resources
   - Remember that the index starts at 0, not 1