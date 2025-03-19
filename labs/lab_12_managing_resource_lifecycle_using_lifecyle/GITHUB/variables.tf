variable "github_owner" {
  description = "GitHub owner (organization or username)"
  type        = string
  default     = "your-github-username" # Replace with your GitHub username or organization
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "repo_visibility" {
  description = "Repository visibility"
  type        = string
  default     = "private"
}