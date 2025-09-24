# Data source outputs
output "current_user" {
  description = "Current GitHub user name"
  value       = data.github_user.current.name
}

output "repository_id" {
  description = "ID of the created repository"
  value       = github_repository.example.repo_id
}

output "repository_html_url" {
  description = "URL of the created repository"
  value       = github_repository.example.html_url
}

output "repository_git_clone_url" {
  description = "Git clone URL of the repository"
  value       = github_repository.example.git_clone_url
}

output "repository_visibility" {
  description = "Visibility of the repository"
  value       = github_repository.example.visibility
}

output "development_repo" {
  description = "The name of the development repo"
  value       = github_repository.development.name
}