terraform {
  required_version = ">= 1.10.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  # The token is automatically read from the GITHUB_TOKEN environment variable
}