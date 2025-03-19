variable "primary_owner" {
  description = "Primary GitHub owner (organization or username)"
  type        = string
  default     = "your-primary-account" # Replace with your primary GitHub username or organization
}

variable "secondary_owner" {
  description = "Secondary GitHub owner (organization or username)"
  type        = string
  default     = "your-secondary-account" # Replace with your secondary GitHub username or organization
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