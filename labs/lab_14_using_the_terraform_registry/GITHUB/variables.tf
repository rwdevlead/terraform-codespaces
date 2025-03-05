variable "organization" {
  description = "GitHub organization name"
  type        = string
  default     = "your-organization"  # Replace with your org name or username
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "repository_visibility" {
  description = "Default repository visibility"
  type        = string
  default     = "private"
}

variable "teams" {
  description = "Map of teams to create"
  type        = map(string)
  default = {
    "developers" = "Repository developers team"
    "operations" = "Infrastructure operations team"
    "security"   = "Security reviewers team"
  }
}