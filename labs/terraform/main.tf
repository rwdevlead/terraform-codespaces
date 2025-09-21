# Create the repository
resource "github_repository" "example" {
  name        = var.repository_name
  description = "Updated repository description" # <-- change description
  visibility  = var.repository_visibility        # <-- update value here

  auto_init = true

  has_issues      = var.repository_features.has_issues      # <-- update value here
  has_discussions = var.repository_features.has_discussions # <-- update value here
  has_wiki        = var.repository_features.has_wiki        # <-- update value here

  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true

  topics = [
    "terraform",
    var.environment,
    "infrastructure-as-code"
  ]

}

# Create branch protection rule
resource "github_branch_protection" "main" {
  repository_id = github_repository.example.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 2 # <-- increase required reviewers
  }
}

# Create development repository
resource "github_repository" "development" {
  name        = var.dev_repository_name
  description = "Primary Dev Repo for new apps"
  visibility  = "public"

  auto_init = true

  has_issues      = var.dev_repo_issues
  has_discussions = var.dev_discussions
  has_wiki        = var.dev_wiki

  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true

  topics = ["terraform", "infrastructure-as-code"]
}

resource "github_branch_protection" "development" {
  repository_id = github_repository.development.node_id
  pattern       = "main"
}

resource "github_branch" "development" {
  repository = github_repository.development.name
  branch     = "main"
}

resource "github_branch_default" "development" {
  repository = github_repository.development.name
  branch     = github_branch.development.branch
}

# Repository Files
resource "github_repository_file" "development" {
  repository          = github_repository.development.name
  branch              = github_branch.development.branch
  file                = ".gitignore"
  content             = "**/*.tfstate"
  commit_message      = "Managed by Terraform"
  commit_author       = "Terraform User"
  commit_email        = "terraform@course.com"
  overwrite_on_create = true
}
