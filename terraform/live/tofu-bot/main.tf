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
  name            = "Tofu Bot"
  username        = "openapi-generator-kotlintoolchain-plugin-tofu-bot"
  access_level    = "reporter"
  token_name      = "Tofu Bot Token used in OpenAPI Generator Kotlin Toolchain Plugin GitLab CI"
  token_scopes    = ["api"]

  token_rotate_before_days       = 14
  token_rotation_expiration_days = 180

  ci_variable_token_name        = "GITLAB_TOFU_MR_PLAN_TOKEN"
  ci_variable_token_hidden      = true
  ci_variable_token_description = "Token used by CI OpenTofu Component to post plans comments on MR"

  avatar_path = "${path.module}/avatar.png"
}
