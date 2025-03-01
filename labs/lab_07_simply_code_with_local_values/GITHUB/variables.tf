variable "organization" {
  description = "GitHub organization name"
  type        = string
  default     = "your-organization"  # Replace with your org name
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "production"
}