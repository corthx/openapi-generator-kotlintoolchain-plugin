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

provider "gitlab" {
  base_url = "https://gitlab.com"
}

module "schedule" {
  source  = "gitlab.com/corthx/pipeline-schedule/gitlab"
  version = "0.0.3"

  project       = "corthx/openapi-generator-kotlintoolchain-plugin"
  description   = "📦 Renovate"
  cron          = "0 10 * * *" # daily, matching the schedule set by hand before this unit; run it from the schedules page to get updates sooner
  cron_timezone = "Europe/Paris"

  variables = {
    SCHEDULE_TASK = "renovate"
  }
}
