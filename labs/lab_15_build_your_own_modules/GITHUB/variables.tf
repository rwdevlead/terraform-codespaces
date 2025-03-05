variable "github_owner" {
  description = "GitHub owner (username or organization)"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}