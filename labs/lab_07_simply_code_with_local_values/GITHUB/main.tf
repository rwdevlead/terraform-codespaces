# Static configuration with repetitive elements
resource "github_repository" "app" {
  name        = "production-application"
  description = "Production application repository"
  visibility  = "private"

  has_issues      = true
  has_wiki        = true
  has_discussions = true
  has_projects    = true

  allow_merge_commit = true
  allow_rebase_merge = true
  allow_squash_merge = true

  delete_branch_on_merge = true
  auto_init              = true

  topics = [
    "production",
    "application",
    "terraform-demo",
    "infrastructure-team"
  ]
}

resource "github_repository" "docs" {
  name        = "production-documentation"
  description = "Production documentation repository"
  visibility  = "private"

  has_issues      = true
  has_wiki        = true
  has_discussions = true
  has_projects    = true

  allow_merge_commit = true
  allow_rebase_merge = true
  allow_squash_merge = true

  delete_branch_on_merge = true
  auto_init              = true

  topics = [
    "production",
    "documentation",
    "terraform-demo",
    "infrastructure-team"
  ]
}

resource "github_team" "developers" {
  name        = "production-developers"
  description = "Production development team"
  privacy     = "closed"
}

resource "github_team" "reviewers" {
  name        = "production-reviewers"
  description = "Production code reviewers team"
  privacy     = "closed"
}

resource "github_team_repository" "app_developers" {
  team_id    = github_team.developers.id
  repository = github_repository.app.name
  permission = "push"
}

resource "github_team_repository" "app_reviewers" {
  team_id    = github_team.reviewers.id
  repository = github_repository.app.name
  permission = "maintain"
}

resource "github_team_repository" "docs_developers" {
  team_id    = github_team.developers.id
  repository = github_repository.docs.name
  permission = "push"
}

resource "github_team_repository" "docs_reviewers" {
  team_id    = github_team.reviewers.id
  repository = github_repository.docs.name
  permission = "maintain"
}