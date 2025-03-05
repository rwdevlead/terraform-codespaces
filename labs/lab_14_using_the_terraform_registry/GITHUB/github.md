# LAB-14-GH: Using Terraform Registry Modules

## Overview
In this lab, you will learn how to use modules from the Terraform Registry to create GitHub infrastructure more efficiently. You'll use two different modules, with one module using the output from another. You'll also call the same module multiple times with different parameters to create similar but unique resources. Finally, you'll use a module with the for_each meta-argument to create multiple instances. The lab uses GitHub free resources to ensure no costs are incurred.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed
- GitHub account
- GitHub personal access token
- Basic understanding of Terraform and GitHub concepts

Note: GitHub credentials are required for this lab.

## Estimated Time
25 minutes

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

variable "repository_visibility" {
  description = "Default repository visibility"
  type        = string
  default     = "private"
}

variable "teams" {
  description = "Map of teams to create"
  type        = map(string)
  default = {
    "developers" = "Repository developers team"
    "operations" = "Infrastructure operations team"
    "security"   = "Security reviewers team"
  }
}
```

## Lab Steps

### 1. Configure GitHub Credentials

Set up your GitHub personal access token:

```bash
export GITHUB_TOKEN="your_personal_access_token"
```

### 2. Use the GitHub Repository Module from Terraform Registry

Create a `main.tf` file and use the GitHub Repository module:

```hcl
# Module 1: GitHub Repository Module from Terraform Registry
module "repository" {
  source  = "mineiros-io/repository/github"
  version = "0.18.0"

  name               = "${var.environment}-app"
  description        = "Application repository for ${var.environment} environment"
  visibility         = var.repository_visibility
  auto_init          = true
  gitignore_template = "Terraform"
  license_template   = "mit"
  
  issue_labels_create = true
  issue_labels = [
    { name = "bug", color = "FF0000", description = "Bug report" },
    { name = "feature", color = "00FF00", description = "Feature request" },
    { name = "documentation", color = "0000FF", description = "Documentation improvement" }
  ]

  plain_files = [
    {
      path    = "README.md"
      content = "# ${var.environment}-app\n\nApplication repository for ${var.environment} environment."
    }
  ]

  defaults = {
    has_issues = true
    has_wiki   = true
  }
}
```

### 3. Use the GitHub Team Module with Repository Output

Add the GitHub Team module, using the repository output from the first module:

```hcl
# Module 2: GitHub Team Module from Terraform Registry
# This module uses the repository output from the repository module
module "team" {
  source  = "mineiros-io/team/github"
  version = "0.8.0"

  name        = "${var.environment}-maintainers"
  description = "Team that maintains the ${var.environment} repository"
  privacy     = "closed"
  
  push_repositories    = [module.repository.repository.name]  # Using output from repository module
  maintain_repositories = [module.repository.repository.name]
}
```

### 4. Call the Team Module a Second Time

Call the team module again with different parameters to create another team:

```hcl
# Call the Team module a second time to create a different team
module "viewers_team" {
  source  = "mineiros-io/team/github"
  version = "0.8.0"

  name        = "${var.environment}-viewers"
  description = "Team that has read access to the ${var.environment} repository"
  privacy     = "closed"
  
  pull_repositories = [module.repository.repository.name]  # Using output from repository module
}
```

### 5. Use Module with For_Each

Now, let's demonstrate how to use the `for_each` meta-argument with a module. Add the following to your `main.tf` file to create multiple teams using the same module:

```hcl
# Module 3: Using Team module with for_each
module "functional_teams" {
  source  = "mineiros-io/team/github"
  version = "0.8.0"
  
  for_each = var.teams

  name        = "${var.environment}-${each.key}"
  description = each.value
  privacy     = "closed"
  
  # Assign different permissions based on team type
  pull_repositories = each.key == "security" ? [module.repository.repository.name] : []
  triage_repositories = each.key == "developers" ? [module.repository.repository.name] : []
  maintain_repositories = each.key == "operations" ? [module.repository.repository.name] : []
}
```

### 6. Add Outputs

Create an `outputs.tf` file to output important information:

```hcl
output "repository_name" {
  description = "The name of the repository"
  value       = module.repository.repository.name
}

output "repository_url" {
  description = "The URL of the repository"
  value       = module.repository.repository.html_url
}

output "maintainers_team_id" {
  description = "The ID of the maintainers team"
  value       = module.team.team.id
}

output "viewers_team_id" {
  description = "The ID of the viewers team"
  value       = module.viewers_team.team.id
}

output "functional_teams" {
  description = "Information about the functional teams"
  value       = { for k, v in module.functional_teams : k => v.team.id }
}
```

### 7. Initialize and Apply

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Notice how Terraform:
- Downloads the modules from the Terraform Registry
- Creates a repository using the GitHub repository module
- Creates teams with different permissions using the team module
- Creates multiple functional teams by using the same module with for_each
- Successfully references the repository name from the first module's output

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
source = "mineiros-io/repository/github"
```
This format (`<NAMESPACE>/<NAME>/<PROVIDER>`) refers to modules in the public Terraform Registry.

### Module Versioning
The `version` attribute pins the module to a specific version:
```
version = "0.18.0"
```
This ensures consistent behavior even if the module is updated in the registry.

### Module Inputs
Each module accepts input variables that control its behavior:
```
name = "${var.environment}-app"
```

### Module Outputs
Modules provide outputs that can be used by other resources:
```
push_repositories = [module.repository.repository.name]
```
Here, the repository name output from the first module is used as an input for the second module.

### Multiple Module Instances
The same module can be called multiple times with different parameters:
```
module "team" {
  name = "${var.environment}-maintainers"
  ...
}

module "viewers_team" {
  name = "${var.environment}-viewers"
  ...
}
```

### Using For_Each with Modules
Modules can be instantiated multiple times using for_each:
```
module "functional_teams" {
  for_each = var.teams
  name = "${var.environment}-${each.key}"
  description = each.value
  ...
}
```
This creates one module instance for each element in the map, with each instance receiving different input values.

## Additional Resources

- [Terraform Registry](https://registry.terraform.io/)
- [Mineiros GitHub Repository Module](https://registry.terraform.io/modules/mineiros-io/repository/github/latest)
- [Mineiros GitHub Team Module](https://registry.terraform.io/modules/mineiros-io/team/github/latest)