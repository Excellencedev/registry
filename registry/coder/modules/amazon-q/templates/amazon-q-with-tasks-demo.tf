terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.17"
    }
  }
}

variable "agent_id" {
  type = string
}

variable "amazon_q_auth_tarball" {
  type        = string
  description = "Base64 encoded, zstd compressed tarball of the Amazon Q auth directory"
}

module "amazon-q" {
  source                  = "../"
  agent_id                = var.agent_id
  experiment_auth_tarball = var.amazon_q_auth_tarball
  install_agentapi        = true
  web_app_display_name    = "Amazon Q"
  web_app_icon            = "/icon/amazon-q.svg"
  web_app_order           = 1
  web_app_group           = "AI Assistants"
  experiment_report_tasks = true
}
