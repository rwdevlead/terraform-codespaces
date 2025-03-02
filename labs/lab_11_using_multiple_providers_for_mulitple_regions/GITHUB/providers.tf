terraform {
  required_version = ">= 1.10.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Primary owner provider
provider "github" {
  owner = var.primary_owner
  alias = "primary"
}

# Secondary owner provider
provider "github" {
  owner = var.secondary_owner
  alias = "secondary"
}