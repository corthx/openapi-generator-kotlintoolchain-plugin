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
  description   = "🔄 Access tokens rotation"
  cron          = "0 9 * * 1" # every Monday 09:00 Paris time — well inside the units' 14-day rotate_before_days window
  cron_timezone = "Europe/Paris"

  variables = {
    SCHEDULE_TASK = "token-rotation"
  }
}
