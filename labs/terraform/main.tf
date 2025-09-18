# Create the repository
resource "github_repository" "example" {
  name        = "terraform-course-repo"
  description = "Updated repository description"  # <-- change description
  visibility  = "public"

  auto_init = true

  has_issues      = true
  has_discussions = true
  has_wiki        = false  # <-- change wiki setting

  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true

  topics = ["terraform", "infrastructure-as-code", "learning"]  # <-- add topic
}

# Create branch protection rule
resource "github_branch_protection" "main" {
  repository_id = github_repository.example.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 2  # <-- increase required reviewers
  }
}
