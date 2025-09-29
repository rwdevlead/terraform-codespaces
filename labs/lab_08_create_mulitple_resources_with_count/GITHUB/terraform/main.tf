# Refactored Repository Resources using count
resource "github_repository" "repo" {
  count       = var.repo_count
  name        = var.repo_names[count.index]
  description = "Example repository ${count.index + 1}"
  visibility  = "public"
  auto_init   = true

  topics = ["example", "terraform", "repo${count.index + 1}"]
}

# dont run, auto_init already creates one.
# Create multiple README files
# resource "github_repository_file" "readme" {
#   count               = var.readme_count
#   repository          = github_repository.repo[count.index].name
#   branch              = "main"
#   file                = "README.md"
#   content             = "# Repository ${count.index + 1}\nThis is an example repository created with Terraform count."
#   commit_message      = "Add README"
#   commit_author       = "Terraform"
#   commit_email        = "terraform@example.com"
#   overwrite_on_create = true
# }

# Refactored Branch Protection resources using count
resource "github_branch_protection" "protection" {
  count         = var.repo_count
  repository_id = github_repository.repo[count.index].node_id
  pattern       = "main"

  allows_deletions                = false
  allows_force_pushes             = false
  require_conversation_resolution = true
}

# # Individual Issue Label Resources
# resource "github_issue_label" "bug1" {
#   repository  = github_repository.repo1.name
#   name        = "bug"
#   color       = "FF0000"
#   description = "Bug issues"
# }

# resource "github_issue_label" "feature1" {
#   repository  = github_repository.repo1.name
#   name        = "feature"
#   color       = "00FF00"
#   description = "Feature requests"
# }

# resource "github_issue_label" "bug2" {
#   repository  = github_repository.repo2.name
#   name        = "bug"
#   color       = "FF0000"
#   description = "Bug issues"
# }

# resource "github_issue_label" "feature2" {
#   repository  = github_repository.repo2.name
#   name        = "feature"
#   color       = "00FF00"
#   description = "Feature requests"
# }