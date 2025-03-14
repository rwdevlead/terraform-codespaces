# Static configuration with hardcoded values
resource "github_repository" "production" {
  name        = "production-application"
  description = "Production application repository"
  visibility  = "public"

  has_issues      = true
  has_wiki        = true
  has_discussions = true

  allow_merge_commit = true
  allow_rebase_merge = true
  allow_squash_merge = true

  topics = [
    "production",
    "application",
    "infrastructure"
  ]
}

resource "github_team" "developers" {
  name        = "production-developers"
  description = "Production development team"
  privacy     = "closed"
}

resource "github_team_repository" "team_access" {
  team_id    = github_team.developers.id
  repository = github_repository.production.name
  permission = "push"
}