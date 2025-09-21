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
