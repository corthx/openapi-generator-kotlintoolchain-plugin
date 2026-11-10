terraform {
  required_version = ">=1.9, <2.0.0"

  backend "http" {}

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      # gitlab_project_service_account_access_token didn't exist before
      # 19.3.0 (19.1.0/19.2.0 had only the group-scoped token resource;
      # 19.0.0 had neither service account resource at all) — floor matches
      # the last of those to land, not just "19.x".
      version = "~> 19.3"
    }
  }
}

locals {
  gitlab_base_url = "https://gitlab.com"
}

provider "gitlab" {
  base_url = local.gitlab_base_url
}

module "bot" {
  source  = "gitlab.com/corthx/service-account/gitlab"
  version = "0.0.3"

  gitlab_base_url = local.gitlab_base_url
  project         = "corthx/openapi-generator-kotlintoolchain-plugin"
  name            = "Renovate Bot"
  username        = "openapi-generator-kotlintoolchain-plugin-renovate-bot"
  # Developer: pushes its own renovate/* branches and opens merge requests,
  # never pushes to protected branches.
  access_level = "developer"
  token_name   = "Renovate Bot Token used in OpenAPI Generator Kotlin Toolchain Plugin GitLab CI"
  # The scopes Renovate documents for the GitLab platform.
  token_scopes = ["api", "read_user", "write_repository"]

  token_rotate_before_days       = 14
  token_rotation_expiration_days = 180

  # Protected: only the renovate schedule, which runs on the default branch,
  # needs these. Unlike the tofu bots' tokens, MR pipelines never do.
  ci_variable_token_name        = "RENOVATE_TOKEN"
  ci_variable_token_protected   = true
  ci_variable_token_hidden      = true
  ci_variable_token_description = "Token used by CI Renovate to open dependency update MRs"

  ci_variable_email_name        = "RENOVATE_GIT_AUTHOR_EMAIL"
  ci_variable_email_protected   = true
  ci_variable_email_description = "Git author email of Renovate's commits, so GitLab attributes them to the bot"

  avatar_path = "${path.module}/avatar.png"
}
