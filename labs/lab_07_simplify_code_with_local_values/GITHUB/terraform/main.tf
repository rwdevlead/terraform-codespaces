# Get information about the current user
data "github_user" "current" {
  username = ""
}

locals {
  # Common repository features
  repo_features = {
    has_issues      = true
    has_wiki        = false
    has_discussions = true
    has_projects    = true
    auto_init       = true
  }

  # Common repository merge settings
  merge_settings = {
    allow_merge_commit     = false
    allow_rebase_merge     = true
    allow_squash_merge     = true
    delete_branch_on_merge = true
  }

  # Common topics
  common_topics = [
    var.environment,
    "terraform-improved-demo",
    "devops-team"
  ]

  # Common name prefix for resources
  name_prefix = "${var.environment}-tf-"

  # Managed by information
  managed_by = "Managed by Terraform (${data.github_user.current.login})"
}

resource "github_repository" "app" {
  name        = "${local.name_prefix}application"                                       # <-- update value here
  description = "${title(var.environment)} application repository. ${local.managed_by}" # <-- update value
  visibility  = "public"

  has_issues      = local.repo_features.has_issues      # <-- update value here
  has_wiki        = local.repo_features.has_wiki        # <-- update value here
  has_discussions = local.repo_features.has_discussions # <-- update value here

  allow_merge_commit = local.merge_settings.allow_merge_commit # <-- update value here
  allow_rebase_merge = local.merge_settings.allow_rebase_merge # <-- update value here
  allow_squash_merge = local.merge_settings.allow_squash_merge # <-- update value here

  delete_branch_on_merge = local.merge_settings.delete_branch_on_merge # <-- update value here
  auto_init              = local.repo_features.auto_init               # <-- update value here

  topics = concat(local.common_topics, ["application"]) # <-- update value here

}

resource "github_repository" "docs" {
  name        = "${local.name_prefix}documentation"
  description = "${title(var.environment)} documentation repository. ${local.managed_by}" # <-- update value here
  visibility  = "public"

  has_issues      = local.repo_features.has_issues      # <-- update value here
  has_wiki        = local.repo_features.has_wiki        # <-- update value here
  has_discussions = local.repo_features.has_discussions # <-- update value here

  allow_merge_commit = local.merge_settings.allow_merge_commit # <-- update value here
  allow_rebase_merge = local.merge_settings.allow_rebase_merge # <-- update value here
  allow_squash_merge = local.merge_settings.allow_squash_merge # <-- update value here

  delete_branch_on_merge = local.merge_settings.delete_branch_on_merge # <-- update value here

  auto_init = local.repo_features.auto_init # <-- update value here

  topics = concat(local.common_topics, ["documentation"]) # <-- update value here

}