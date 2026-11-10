terraform {
  required_version = ">=1.9, <2.0.0"

  backend "http" {}

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 19.3"
    }
  }
}

locals {
  project = "corthx/openapi-generator-kotlintoolchain-plugin"
}

provider "gitlab" {
  base_url = "https://gitlab.com"
}

module "boards" {
  source  = "gitlab.com/corthx/issue-board/gitlab"
  version = "0.0.3"

  scope   = "project"
  project = local.project

  boards = {
    "Development" = {
      lists = ["internal", "enhancement", "documentation"],
    },
    "Community follow up" = {
      lists = ["question", "needs more details", "help wanted"],
    },
    "Maintenance" = {
      lists = ["bug", "breaking change", "dependencies"],
    },
  }
}
