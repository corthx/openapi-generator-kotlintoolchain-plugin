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

module "labels" {
  source  = "gitlab.com/corthx/label/gitlab"
  version = "0.0.3"

  project = local.project

  labels = {
    "breaking change" = {
      description = "Introduces a change that is not backwards-compatible",
      color       = "#b60205",
    },
    "bug" = {
      description = "Something isn't working as expected",
      color       = "#d9534f",
    },
    "dependencies" = {
      description = "Related to dependency updates or version bumps",
      color       = "#0366d6",
    },
    "documentation" = {
      description = "Improvements or additions to docs",
      color       = "#0075ca",
    },
    "duplicate" = {
      description = "This issue or PR already exists elsewhere",
      color       = "#cccccc",
    },
    "enhancement" = {
      description = "New feature or improvement to existing functionality",
      color       = "#5cb85c",
    },
    "help wanted" = {
      description = "Community contributions are welcome on this item",
      color       = "#008672",
    },
    "internal" = {
      description = "Changes to internal tooling, pipelines, or project infrastructure (not user-facing)",
      color       = "#6e6e6e",
    },
    "invalid" = {
      description = "This report is incorrect, out of scope, or cannot be reproduced",
      color       = "#cccccc",
    },
    "needs more details" = {
      description = "Need additional details to move forward",
      color       = "#e8892b",
    },
    "question" = {
      description = "A question about usage or behavior",
      color       = "#d876e3",
    },
    # Applied by Renovate to vulnerability fixes (renovate.json5).
    "security" = {
      description = "Issues and changes related to security vulnerabilities, authentication, authorization, or sensitive data handling",
      color       = "#D9534F",
    },
    "tofu:apply" = {
      description = "Applying this label on MR exposes a manual apply for all lives",
      color       = "#7B42BC", # Terraform's brand purple
    },
    "tofu:plan" = {
      description = "Applying this label on MR triggers plan for all lives",
      color       = "#7B42BC", # Terraform's brand purple
    },
    "wontfix" = {
      description = "This will not be addressed; see comments for rationale",
      color       = "#cccccc",
    },
  }
}
