# Static configuration with hardcoded values

# Get information about the current user
data "github_user" "current" {
  username = ""
}

resource "github_repository" "production" {
  name        = "${var.environment}-${var.app_name}"                                                            # <-- update value here
  description = "${title(var.environment)} environment repository managed by ${data.github_user.current.login}" # <-- update value here
  visibility  = "public"

  has_issues      = var.repository_features.has_issues      # <-- update value here
  has_wiki        = var.repository_features.has_wiki        # <-- update value here
  has_discussions = var.repository_features.has_discussions # <-- update value here

  allow_merge_commit = true
  allow_rebase_merge = true
  allow_squash_merge = true

  topics = [
    var.environment, # <-- update value here
    var.app_name,    # <-- update value here
    "infrastructure"
  ]
}