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

# Amazon Q with full AgentAPI integration
# This configuration provides both web and CLI access to Amazon Q
# with task reporting enabled
module "amazon-q" {
  source                  = "../"
  agent_id                = var.agent_id
  experiment_auth_tarball = var.amazon_q_auth_tarball
  
  # AgentAPI integration for web interface and task reporting
  install_agentapi        = true
  agentapi_version        = "v0.3.3"
  agentapi_port           = 3284
  
  # Web app configuration
  web_app_display_name    = "Amazon Q Chat"
  web_app_icon            = "/icon/amazon-q.svg"
  web_app_order           = 1
  web_app_group           = "AI Assistants"
  
  # CLI app configuration
  cli_app                 = true
  cli_app_display_name    = "Amazon Q CLI"
  cli_app_icon            = "/icon/terminal.svg"
  cli_app_order           = 2
  cli_app_group           = "AI Assistants"
  
  # Task reporting
  experiment_report_tasks = true
  
  # System prompt customization
  system_prompt           = "You are an expert software developer working in a Coder workspace. Help the user with their coding tasks."
  
  # Initial task prompt
  ai_prompt               = "Review the project files and suggest improvements."
}
