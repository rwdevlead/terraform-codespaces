# LAB-04-GH: Managing Multiple Resources and Dependencies

# **Please note that I am rebuilding this lab - steps below may not work as expected**

## Overview
In this lab, you will expand your GitHub repository configuration by adding multiple interconnected resources. You'll learn how Terraform manages dependencies between resources and how to structure more complex configurations. We'll create teams, manage repository permissions, and implement branch protection rules, demonstrating how different GitHub resources work together.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- GitHub account with appropriate permissions
- GitHub organization admin access
- Completion of LAB-03-GH with existing repository configuration

## Estimated Time
30 minutes

## Lab Steps

### 1. Add New Variable Definitions

Add the following to your existing `variables.tf`:

```hcl
# Team Variables
variable "team_name" {
  description = "Name of the development team"
  type        = string
  default     = "terraform-team"
}

variable "team_description" {
  description = "Description of the team"
  type        = string
  default     = "Team managed by Terraform"
}

variable "required_reviewers" {
  description = "Number of required reviewers for pull requests"
  type        = number
  default     = 2
}
```

### 2. Configure Team Repository Access

Add team permissions for the repository in `main.tf`:

```hcl
# Team Repository Access
resource "github_team_repository" "developers_access" {
  team_id    = github_team.developers.id
  repository = github_repository.example.name
  permission = "push"
}

resource "github_team_repository" "reviewers_access" {
  team_id    = github_team.reviewers.id
  repository = github_repository.example.name
  permission = "maintain"
}
```

### 3. Create Branch Protection Rules

Modify/Replace the branch protection rules that reference the teams - this is the second resource block we created in `main.tf`:

```hcl
# Branch Protection
resource "github_branch_protection" "main" {
  repository_id = github_repository.example.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = var.required_reviewers
    dismiss_stale_reviews          = true
    require_code_owner_reviews     = true
  }

  required_status_checks {
    strict = true
  }

  restrict_pushes {
    push_allowances = [github_team.reviewers.node_id]
  }
}
```

### 4. Add Repository Files

Create a CODEOWNERS file in the repository:

```hcl
# Repository Files
resource "github_repository_file" "codeowners" {
  repository          = github_repository.example.name
  branch             = "main"
  file               = "CODEOWNERS"
  content            = "*"
  commit_message     = "Add CODEOWNERS file"
  overwrite_on_create = true

  depends_on = [
    github_branch_protection.main
  ]
}
```

> Note the explicit dependency on the branch protection rule to ensure the file can be created after the branch is protected.

### 5. Add New Outputs

Add the following output blocks to your `outputs.tf` file to see information about the newly created subnets:

```hcl
************   add outputs here   *********
```

### 6. Update terraform.tfvars

Add the team values to your existing `terraform.tfvars`:

```hcl
# Team Variables
team_name        = "terraform-course"
team_description = "Team for Terraform training course"
required_reviewers = 2
```

### 7. Apply the Configuration

Run the following commands:
```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Review the proposed changes and type `yes` when prompted to confirm.

## Understanding Resource Dependencies

Notice how Terraform automatically determines the order of resource creation:
1. Teams must be created before repository permissions can be granted
2. The repository must exist before branch protection rules can be applied
3. Branch protection must be in place before the CODEOWNERS file can be added

This is handled through both implicit dependencies (where Terraform determines relationships based on resource references) and explicit dependencies (using depends_on).

## Verification Steps

In the GitHub web interface:
1. Navigate to your repository's settings
2. Verify the teams exist and have the correct permissions
3. Check the branch protection rules
4. Confirm the CODEOWNERS file exists and is properly configured

## Success Criteria
Your lab is successful if:
- All resources are created successfully
- Resource dependencies are properly maintained
- Teams have the correct permissions
- Branch protection rules are properly configured
- The CODEOWNERS file is created and references the correct team

## Additional Exercises
1. Add more team members to the teams
2. Create additional branch protection rules for other branches
3. Add more repository files using Terraform
4. Modify team permissions and observe the changes

## Common Issues and Solutions

If you see errors:
- Verify GitHub organization permissions
- Ensure team names are unique within your organization
- Check that branch names match exactly
- Verify your GitHub token has sufficient permissions

## Next Steps
In the next lab, we will learn about state management. Keep your Terraform configuration files intact, as we will continue to expand upon them.