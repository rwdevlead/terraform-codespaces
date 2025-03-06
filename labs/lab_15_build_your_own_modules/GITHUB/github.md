# LAB-15-GitHub: Creating and Using Local Modules

## Overview
In this lab, you will create your own local Terraform modules and use them to manage GitHub resources. You'll create three modules - one for GitHub repositories, one for GitHub teams, and one for branch protection rules - and then call these modules from a parent configuration. This lab teaches you how to build reusable modules, pass variables between modules, and organize your Terraform code efficiently.

**Preview Mode**: Use `Cmd/Ctrl + Shift + V` in VSCode to see a nicely formatted version of this lab!

## Prerequisites
- Terraform installed (v1.0.0+)
- GitHub account
- GitHub personal access token with appropriate permissions
- Basic understanding of Terraform and GitHub concepts

Note: A GitHub personal access token is required for this lab. Make sure it has the following permissions:
- `repo` (Full control of private repositories)
- `admin:org` (Full control of orgs and teams, read and write org projects)

## How to Use This Hands-On Lab

1. **Create a Codespace** from this repo (click the button below).  
2. Once the Codespace is running, open the integrated terminal.
3. Follow the instructions in each **lab** to complete the exercises.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/btkrausen/terraform-codespaces)

## Estimated Time
40 minutes

## Lab Steps

### 1. Configure GitHub Credentials

```bash
export GITHUB_TOKEN="your_github_token"
export GITHUB_OWNER="your_github_username_or_org"
```

### 2. Create the Directory Structure

Create the following directory structure for your project:

```bash
mkdir -p modules/github_repository
mkdir -p modules/github_team
mkdir -p modules/branch_protection
```

Alternatively, you can create these directories and files using the VSCode UI if you prefer:
- Right-click in the Explorer panel and select "New Folder" to create the "modules" directory
- Right-click on "modules" and create the subdirectories
- Right-click in the main directory and select "New File" to create each of the .tf files

### 3. Create the Providers File

Add the following content to `providers.tf`:

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
  owner = var.github_owner
  # The token is automatically read from the GITHUB_TOKEN environment variable
}
```

### 4. Create the Variables File

Add the following content to `variables.tf`:

```hcl
variable "github_owner" {
  description = "GitHub owner (username or organization)"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
```

### 5. Create the GitHub Repository Module

Create the following files in the `modules/github_repository` directory:

#### a. Create `modules/github_repository/variables.tf`:

```hcl
variable "name" {
  description = "Name of the repository"
  type        = string
}

variable "description" {
  description = "Description of the repository"
  type        = string
  default     = ""
}

variable "visibility" {
  description = "Visibility of the repository"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of: public, private, or internal."
  }
}

variable "has_issues" {
  description = "Enable issues feature"
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Enable projects feature"
  type        = bool
  default     = false
}

variable "has_wiki" {
  description = "Enable wiki feature"
  type        = bool
  default     = false
}

variable "auto_init" {
  description = "Initialize the repository with a README"
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Gitignore template to use"
  type        = string
  default     = null
}

variable "license_template" {
  description = "License template to use"
  type        = string
  default     = null
}

variable "topics" {
  description = "List of topics for the repository"
  type        = list(string)
  default     = []
}

variable "template" {
  description = "Template repository to use"
  type = object({
    owner      = string
    repository = string
  })
  default = null
}
```

#### b. Create `modules/github_repository/main.tf`:

```hcl
resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility

  has_issues   = var.has_issues
  has_projects = var.has_projects
  has_wiki     = var.has_wiki

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template
  topics             = var.topics

  dynamic "template" {
    for_each = var.template != null ? [var.template] : []
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }
}
```

#### c. Create `modules/github_repository/outputs.tf`:

```hcl
output "repo_id" {
  description = "ID of the repository"
  value       = github_repository.this.repo_id
}

output "full_name" {
  description = "Full name of the repository"
  value       = github_repository.this.full_name
}

output "html_url" {
  description = "HTML URL of the repository"
  value       = github_repository.this.html_url
}

output "ssh_clone_url" {
  description = "SSH clone URL of the repository"
  value       = github_repository.this.ssh_clone_url
}

output "git_clone_url" {
  description = "Git clone URL of the repository"
  value       = github_repository.this.git_clone_url
}

output "name" {
  description = "Name of the repository"
  value       = github_repository.this.name
}
```

### 6. Create the GitHub Team Module

Create the following files in the `modules/github_team` directory:

#### a. Create `modules/github_team/variables.tf`:

```hcl
variable "name" {
  description = "Name of the team"
  type        = string
}

variable "description" {
  description = "Description of the team"
  type        = string
  default     = ""
}

variable "privacy" {
  description = "Privacy of the team"
  type        = string
  default     = "closed"
  validation {
    condition     = contains(["secret", "closed"], var.privacy)
    error_message = "Privacy must be one of: secret or closed."
  }
}

variable "parent_team_id" {
  description = "ID of the parent team, if this is a nested team"
  type        = string
  default     = null
}

variable "ldap_dn" {
  description = "LDAP Distinguished Name for the team"
  type        = string
  default     = null
}

variable "create_default_maintainer" {
  description = "Adds the creating user as a maintainer"
  type        = bool
  default     = true
}
```

#### b. Create `modules/github_team/main.tf`:

```hcl
resource "github_team" "this" {
  name                      = var.name
  description               = var.description
  privacy                   = var.privacy
  parent_team_id            = var.parent_team_id
  ldap_dn                   = var.ldap_dn
  create_default_maintainer = var.create_default_maintainer
}
```

#### c. Create `modules/github_team/outputs.tf`:

```hcl
output "team_id" {
  description = "ID of the team"
  value       = github_team.this.id
}

output "slug" {
  description = "Slug of the team"
  value       = github_team.this.slug
}

output "node_id" {
  description = "Node ID of the team"
  value       = github_team.this.node_id
}

output "name" {
  description = "Name of the team"
  value       = github_team.this.name
}
```

### 7. Create the Branch Protection Module

Create the following files in the `modules/branch_protection` directory:

#### a. Create `modules/branch_protection/variables.tf`:

```hcl
variable "repository_name" {
  description = "Name of the repository"
  type        = string
}

variable "branch" {
  description = "Branch to protect"
  type        = string
  default     = "main"
}

variable "enforce_admins" {
  description = "Enforce on repository administrators"
  type        = bool
  default     = true
}

variable "require_signed_commits" {
  description = "Require signed commits"
  type        = bool
  default     = false
}

variable "required_status_checks" {
  description = "Status checks that are required"
  type = object({
    strict   = bool
    contexts = list(string)
  })
  default = null
}

variable "required_pull_request_reviews" {
  description = "Pull request review requirements"
  type = object({
    dismiss_stale_reviews           = bool
    restrict_dismissals             = bool
    require_code_owner_reviews      = bool
    required_approving_review_count = number
    dismissal_restrictions          = list(string)
  })
  default = null
}

variable "push_restrictions" {
  description = "List of user/team names with push access"
  type        = list(string)
  default     = []
}

variable "allows_deletions" {
  description = "Allow users with push access to delete the branch"
  type        = bool
  default     = false
}

variable "allows_force_pushes" {
  description = "Allow force pushes to the branch"
  type        = bool
  default     = false
}
```

#### b. Create `modules/branch_protection/main.tf`:

```hcl
resource "github_branch_protection" "this" {
  repository_id = var.repository_name
  pattern       = var.branch

  enforce_admins = var.enforce_admins
  
  require_signed_commits = var.require_signed_commits
  allows_deletions       = var.allows_deletions
  allows_force_pushes    = var.allows_force_pushes

  dynamic "required_status_checks" {
    for_each = var.required_status_checks != null ? [var.required_status_checks] : []
    content {
      strict   = required_status_checks.value.strict
      contexts = required_status_checks.value.contexts
    }
  }

  dynamic "required_pull_request_reviews" {
    for_each = var.required_pull_request_reviews != null ? [var.required_pull_request_reviews] : []
    content {
      dismiss_stale_reviews           = required_pull_request_reviews.value.dismiss_stale_reviews
      restrict_dismissals             = required_pull_request_reviews.value.restrict_dismissals
      require_code_owner_reviews      = required_pull_request_reviews.value.require_code_owner_reviews
      required_approving_review_count = required_pull_request_reviews.value.required_approving_review_count
      dismissal_restrictions          = required_pull_request_reviews.value.dismissal_restrictions
    }
  }

  dynamic "push_restrictions" {
    for_each = length(var.push_restrictions) > 0 ? [var.push_restrictions] : []
    content {
      users = []
      teams = push_restrictions.value
    }
  }
}
```

#### c. Create `modules/branch_protection/outputs.tf`:

```hcl
output "protected_branch" {
  description = "Name of the protected branch"
  value       = var.branch
}

output "repository_name" {
  description = "Name of the repository"
  value       = var.repository_name
}
```

### 8. Create the Main Configuration

Add the following content to `main.tf` to use your local modules:

```hcl
# Create repositories using the github_repository module
module "api_repository" {
  source      = "./modules/github_repository"
  name        = "api-${var.environment}"
  description = "API service repository"
  visibility  = "private"
  
  has_issues   = true
  has_projects = true
  has_wiki     = true
  auto_init    = true
  
  gitignore_template = "Node"
  license_template   = "mit"
  
  topics = ["api", "service", var.environment]
}

module "frontend_repository" {
  source      = "./modules/github_repository"
  name        = "frontend-${var.environment}"
  description = "Frontend application repository"
  visibility  = "private"
  
  has_issues   = true
  has_projects = true
  has_wiki     = false
  auto_init    = true
  
  gitignore_template = "Node"
  license_template   = "mit"
  
  topics = ["frontend", "react", var.environment]
}

# Create teams using the github_team module
module "developers_team" {
  source      = "./modules/github_team"
  name        = "developers-${var.environment}"
  description = "Developers team for ${var.environment} environment"
  privacy     = "closed"
}

module "devops_team" {
  source      = "./modules/github_team"
  name        = "devops-${var.environment}"
  description = "DevOps team for ${var.environment} environment"
  privacy     = "closed"
}

# Add team repositories access
resource "github_team_repository" "developers_api" {
  team_id    = module.developers_team.team_id
  repository = module.api_repository.name
  permission = "push"
}

resource "github_team_repository" "developers_frontend" {
  team_id    = module.developers_team.team_id
  repository = module.frontend_repository.name
  permission = "push"
}

resource "github_team_repository" "devops_api" {
  team_id    = module.devops_team.team_id
  repository = module.api_repository.name
  permission = "admin"
}

resource "github_team_repository" "devops_frontend" {
  team_id    = module.devops_team.team_id
  repository = module.frontend_repository.name
  permission = "admin"
}

# Apply branch protection rules using the branch_protection module
module "api_branch_protection" {
  source          = "./modules/branch_protection"
  repository_name = module.api_repository.name
  branch          = "main"
  
  enforce_admins         = true
  require_signed_commits = false
  
  required_status_checks = {
    strict   = true
    contexts = ["ci/github-actions"]
  }
  
  required_pull_request_reviews = {
    dismiss_stale_reviews           = true
    restrict_dismissals             = false
    require_code_owner_reviews      = true
    required_approving_review_count = 1
    dismissal_restrictions          = []
  }
  
  push_restrictions  = [module.devops_team.slug]
  allows_deletions   = false
  allows_force_pushes = false
}

module "frontend_branch_protection" {
  source          = "./modules/branch_protection"
  repository_name = module.frontend_repository.name
  branch          = "main"
  
  enforce_admins         = true
  require_signed_commits = false
  
  required_status_checks = {
    strict   = true
    contexts = ["ci/github-actions"]
  }
  
  required_pull_request_reviews = {
    dismiss_stale_reviews           = true
    restrict_dismissals             = false
    require_code_owner_reviews      = true
    required_approving_review_count = 1
    dismissal_restrictions          = []
  }
  
  push_restrictions  = [module.devops_team.slug]
  allows_deletions   = false
  allows_force_pushes = false
}
```

### 9. Create the Outputs File

Add the following content to `outputs.tf`:

```hcl
output "repository_urls" {
  description = "URLs of the created repositories"
  value = {
    api      = module.api_repository.html_url,
    frontend = module.frontend_repository.html_url
  }
}

output "team_slugs" {
  description = "Slugs of the created teams"
  value = {
    developers = module.developers_team.slug,
    devops     = module.devops_team.slug
  }
}

output "protected_branches" {
  description = "Information about protected branches"
  value = {
    api      = "${module.api_branch_protection.repository_name}:${module.api_branch_protection.protected_branch}",
    frontend = "${module.frontend_branch_protection.repository_name}:${module.frontend_branch_protection.protected_branch}"
  }
}

output "clone_urls" {
  description = "Clone URLs for the repositories"
  value = {
    api = {
      ssh = module.api_repository.ssh_clone_url,
      https = module.api_repository.git_clone_url
    },
    frontend = {
      ssh = module.frontend_repository.ssh_clone_url,
      https = module.frontend_repository.git_clone_url
    }
  }
}
```

### 10. Initialize and Apply

Initialize and apply the configuration:

```bash
terraform init
terraform plan
terraform apply
```

Watch how Terraform:
- Processes each local module
- Creates GitHub repositories with the repository module
- Creates GitHub teams with the team module
- Applies branch protection rules with the branch protection module
- Sets up team repository access

### 11. Add a GitHub Action Workflow

Let's create a simple GitHub Action workflow for one of the repositories:

1. Create a new file in your project root called `workflow.yml`:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16.x'
    - name: Install dependencies
      run: npm ci
    - name: Run tests
      run: npm test
    - name: Build
      run: npm run build
```

2. Add a new file in your project root called `push_workflow.tf`:

```hcl
resource "github_repository_file" "api_workflow" {
  repository          = module.api_repository.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/workflow.yml")
  commit_message      = "Add CI workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
  
  depends_on = [module.api_repository]
}

resource "github_repository_file" "frontend_workflow" {
  repository          = module.frontend_repository.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  content             = file("${path.module}/workflow.yml")
  commit_message      = "Add CI workflow"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
  
  depends_on = [module.frontend_repository]
}
```

3. Apply the changes:

```bash
terraform apply
```

### 12. Create Another Module for Repository File Creation

Let's create another module to manage repository files:

#### a. Create a new directory for the repository files module:

```bash
mkdir -p modules/repository_files
```

#### b. Create `modules/repository_files/variables.tf`:

```hcl
variable "repository" {
  description = "Name of the repository"
  type        = string
}

variable "branch" {
  description = "Branch to commit to"
  type        = string
  default     = "main"
}

variable "files" {
  description = "Map of file paths to their content"
  type        = map(string)
}

variable "commit_message" {
  description = "Commit message"
  type        = string
  default     = "Add files via Terraform"
}

variable "commit_author" {
  description = "Commit author name"
  type        = string
  default     = "Terraform"
}

variable "commit_email" {
  description = "Commit author email"
  type        = string
  default     = "terraform@example.com"
}

variable "overwrite_on_create" {
  description = "Enable overwriting existing files"
  type        = bool
  default     = true
}
```

#### c. Create `modules/repository_files/main.tf`:

```hcl
resource "github_repository_file" "files" {
  for_each            = var.files
  
  repository          = var.repository
  branch              = var.branch
  file                = each.key
  content             = each.value
  commit_message      = var.commit_message
  commit_author       = var.commit_author
  commit_email        = var.commit_email
  overwrite_on_create = var.overwrite_on_create
}
```

#### d. Create `modules/repository_files/outputs.tf`:

```hcl
output "repository" {
  description = "Repository name"
  value       = var.repository
}

output "files" {
  description = "List of created files"
  value       = [for path, _ in var.files : path]
}
```

#### e. Create repository files using the module:

Update your `main.tf` file by adding:

```hcl
# Create README and other repository files
module "api_repo_files" {
  source     = "./modules/repository_files"
  repository = module.api_repository.name
  branch     = "main"
  
  files = {
    "README.md" = <<-EOT
      # API Service
      
      This is the API service for the ${var.environment} environment.
      
      ## Getting Started
      
      1. Clone the repository
      2. Install dependencies: `npm install`
      3. Start the development server: `npm run dev`
      
      ## Available Scripts
      
      - `npm run dev`: Starts the development server
      - `npm run build`: Builds the application
      - `npm run test`: Runs the test suite
      - `npm run lint`: Runs the linter
    EOT,
    
    ".env.example" = <<-EOT
      # Environment Variables
      PORT=3000
      NODE_ENV=development
      DATABASE_URL=postgres://localhost:5432/api_${var.environment}
    EOT,
    
    "package.json" = <<-EOT
      {
        "name": "api-${var.environment}",
        "version": "1.0.0",
        "description": "API service",
        "main": "index.js",
        "scripts": {
          "dev": "nodemon src/index.js",
          "start": "node src/index.js",
          "test": "jest",
          "lint": "eslint ."
        },
        "dependencies": {
          "express": "^4.17.1"
        },
        "devDependencies": {
          "jest": "^27.0.6",
          "nodemon": "^2.0.12",
          "eslint": "^7.32.0"
        }
      }
    EOT
  }
}

module "frontend_repo_files" {
  source     = "./modules/repository_files"
  repository = module.frontend_repository.name
  branch     = "main"
  
  files = {
    "README.md" = <<-EOT
      # Frontend Application
      
      This is the frontend application for the ${var.environment} environment.
      
      ## Getting Started
      
      1. Clone the repository
      2. Install dependencies: `npm install`
      3. Start the development server: `npm run dev`
      
      ## Available Scripts
      
      - `npm run dev`: Starts the development server
      - `npm run build`: Builds the application
      - `npm run test`: Runs the test suite
      - `npm run lint`: Runs the linter
    EOT,
    
    ".env.example" = <<-EOT
      # Environment Variables
      VITE_API_URL=http://localhost:3000
      VITE_APP_ENV=${var.environment}
    EOT,
    
    "package.json" = <<-EOT
      {
        "name": "frontend-${var.environment}",
        "version": "1.0.0",
        "description": "Frontend application",
        "scripts": {
          "dev": "vite",
          "build": "vite build",
          "test": "vitest run",
          "lint": "eslint ."
        },
        "dependencies": {
          "react": "^18.2.0",
          "react-dom": "^18.2.0"
        },
        "devDependencies": {
          "vite": "^4.0.0",
          "vitest": "^0.25.3",
          "eslint": "^8.30.0"
        }
      }
    EOT
  }
}
```

3. Apply the changes:

```bash
terraform apply
```

### 13. Clean Up

When finished with the lab, clean up all created resources:

```bash
terraform destroy
```

## Understanding Local Modules for GitHub Resources

Let's examine the key aspects of creating and using local modules with GitHub:

### Module Structure
A well-structured GitHub module typically contains:
- `main.tf` - The main resource definitions
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output definitions

### Module Source
For local modules, the source is a relative path:
```
source = "./modules/github_repository"
```

### Module Inputs
Modules receive input through variables:
```
module "api_repository" {
  source      = "./modules/github_repository"
  name        = "api-${var.environment}"
  ...
}
```

### Module Outputs
Modules provide outputs that can be referenced:
```
module.api_repository.name
```

### Module Reuse
The same module can be used multiple times with different parameters:
```
module "api_repository" { ... }
module "frontend_repository" { ... }
```

## Benefits of Using Local Modules with GitHub

1. **Standardization**: Create standardized repository settings across your organization
2. **Policy Enforcement**: Ensure branch protection and security policies are consistently applied
3. **Repository Templates**: Create new repositories with predefined settings and files
4. **Organization**: Keep related GitHub resources grouped together
5. **Maintainability**: Update GitHub settings in one place and apply to multiple resources

## Additional Exercises

1. Create a module for GitHub repository webhooks
2. Extend the repository module to handle collaborators
3. Create a module for GitHub issue labels with standard labels
4. Add support for repository secrets management
5. Create a module for GitHub Pages configuration

## Tips for Working with GitHub Modules

1. **Authentication**: Always use environment variables for GitHub tokens rather than hardcoding
2. **Idempotency**: Understand the implications of changing resources in GitHub
3. **Private vs Public**: Be careful when creating public repositories with sensitive information
4. **Permissions**: Ensure your GitHub token has the necessary permissions
5. **Drift Detection**: Be aware that manual changes in GitHub UI can cause drift in your Terraform state