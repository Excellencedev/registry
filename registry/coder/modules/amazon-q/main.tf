terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.7"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

variable "order" {
  type        = number
  description = "The order determines the position of app in the UI presentation. The lowest order is shown first and apps with equal order are sorted by name (ascending order)."
  default     = null
}

variable "group" {
  type        = string
  description = "The name of a group that this app belongs to."
  default     = null
}

variable "icon" {
  type        = string
  description = "The icon to use for the app."
  default     = "/icon/amazon-q.svg"
}

variable "folder" {
  type        = string
  description = "The folder to run Amazon Q in."
  default     = "/home/coder"
}

variable "install_amazon_q" {
  type        = bool
  description = "Whether to install Amazon Q."
  default     = true
}

variable "amazon_q_version" {
  type        = string
  description = "The version of Amazon Q to install."
  default     = "latest"
}

variable "experiment_use_screen" {
  type        = bool
  description = "Whether to use screen for running Amazon Q in the background."
  default     = false
}

variable "experiment_use_tmux" {
  type        = bool
  description = "Whether to use tmux instead of screen for running Amazon Q in the background."
  default     = false
}

variable "experiment_report_tasks" {
  type        = bool
  description = "Whether to enable task reporting."
  default     = false
}

variable "experiment_pre_install_script" {
  type        = string
  description = "Custom script to run before installing Amazon Q."
  default     = null
}

variable "experiment_post_install_script" {
  type        = string
  description = "Custom script to run after installing Amazon Q."
  default     = null
}

variable "install_agentapi" {
  type        = bool
  description = "Whether to install AgentAPI."
  default     = true
}

variable "agentapi_version" {
  type        = string
  description = "The version of AgentAPI to install."
  default     = "v0.3.3"
}

variable "agentapi_subdomain" {
  type        = bool
  description = "Whether to use a subdomain for AgentAPI."
  default     = true
}

variable "agentapi_port" {
  type        = number
  description = "The port used by AgentAPI."
  default     = 3284
}

variable "web_app_order" {
  type        = number
  description = "The order determines the position of app in the UI presentation. The lowest order is shown first and apps with equal order are sorted by name (ascending order)."
  default     = null
}

variable "web_app_group" {
  type        = string
  description = "The name of a group that this app belongs to."
  default     = null
}

variable "web_app_icon" {
  type        = string
  description = "The icon to use for the app."
  default     = "/icon/amazon-q.svg"
}

variable "web_app_display_name" {
  type        = string
  description = "The display name of the web app."
  default     = "Amazon Q"
}

variable "cli_app" {
  type        = bool
  description = "Whether to create the CLI workspace app."
  default     = false
}

variable "cli_app_order" {
  type        = number
  description = "The order of the CLI workspace app."
  default     = null
}

variable "cli_app_group" {
  type        = string
  description = "The group of the CLI workspace app."
  default     = null
}

variable "cli_app_icon" {
  type        = string
  description = "The icon to use for the app."
  default     = "/icon/amazon-q.svg"
}

variable "cli_app_display_name" {
  type        = string
  description = "The display name of the CLI workspace app."
  default     = "Amazon Q CLI"
}

variable "cli_app_slug" {
  type        = string
  description = "The slug of the CLI workspace app."
  default     = "amazon-q-cli"
}

variable "experiment_auth_tarball" {
  type        = string
  description = "Base64 encoded, zstd compressed tarball of a pre-authenticated ~/.local/share/amazon-q directory. After running `q login` on another machine, you may generate it with: `cd ~/.local/share/amazon-q && tar -c . | zstd | base64 -w 0`"
  default     = "tarball"
}

variable "system_prompt" {
  type        = string
  description = "The system prompt to use for Amazon Q. This should instruct the agent how to do task reporting."
  default     = <<-EOT
    You are a helpful Coding assistant. Aim to autonomously investigate
    and solve issues the user gives you and test your work, whenever possible.
    Avoid shortcuts like mocking tests. When you get stuck, you can ask the user
    but opt for autonomy.

    YOU MUST REPORT ALL TASKS TO CODER.
    When reporting tasks, you MUST follow these EXACT instructions:
    - IMMEDIATELY report status after receiving ANY user message.
    - Be granular. If you are investigating with multiple steps, report each step to coder.

    Task state MUST be one of the following:
    - Use "state": "working" when actively processing WITHOUT needing additional user input.
    - Use "state": "complete" only when finished with a task.
    - Use "state": "failure" when you need ANY user input, lack sufficient details, or encounter blockers.

    Task summaries MUST:
    - Include specifics about what you're doing.
    - Include clear and actionable steps for the user.
    - Be less than 160 characters in length.
  EOT
}

variable "ai_prompt" {
  type        = string
  description = "The initial task prompt to send to Amazon Q."
  default     = "Please help me with my coding tasks. I'll provide specific instructions as needed."
}

variable "pre_install_script" {
  type        = string
  description = "Custom script to run before installing the agent used by AgentAPI."
  default     = null
}

variable "post_install_script" {
  type        = string
  description = "Custom script to run after installing the agent used by AgentAPI."
  default     = null
}

variable "module_dir_name" {
  type        = string
  description = "Name of the subdirectory in the home directory for module files."
  default     = ".amazon-q-module"
}

locals {
  encoded_pre_install_script  = var.experiment_pre_install_script != null ? base64encode(var.experiment_pre_install_script) : ""
  encoded_post_install_script = var.experiment_post_install_script != null ? base64encode(var.experiment_post_install_script) : ""
  full_prompt                 = <<-EOT
    ${var.system_prompt}

    Your first task is:

    ${var.ai_prompt}
  EOT
  app_slug                    = "amazon-q"
  base_extensions             = <<-EOT
coder:
  args:
  - exp
  - mcp
  - server
  - --allowed-tools
  - coder_report_task
  cmd: coder
  description: Report ALL tasks and statuses (in progress, done, failed) you are working on.
  enabled: true
  envs:
    CODER_MCP_APP_STATUS_SLUG: ${local.app_slug}
  name: Coder
  timeout: 3000
  type: stdio
EOT
  # Add two spaces to each line of extensions to match YAML structure
  formatted_base              = "  ${replace(trimspace(local.base_extensions), "\n", "\n  ")}"
  combined_extensions         = <<-EOT
extensions:
${local.formatted_base}
EOT
  install_script              = file("${path.module}/scripts/install.sh")
  start_script                = file("${path.module}/scripts/start.sh")
}

module "agentapi" {
  source  = "registry.coder.com/coder/agentapi/coder"
  version = "1.1.1"

  agent_id             = var.agent_id
  web_app_slug         = local.app_slug
  web_app_order        = var.web_app_order
  web_app_group        = var.web_app_group
  web_app_icon         = var.web_app_icon
  web_app_display_name = var.web_app_display_name
  cli_app              = var.cli_app
  cli_app_order        = var.cli_app_order
  cli_app_group        = var.cli_app_group
  cli_app_icon         = var.cli_app_icon
  cli_app_display_name = var.cli_app_display_name
  cli_app_slug         = var.cli_app_slug
  module_dir_name      = var.module_dir_name
  install_agentapi     = var.install_agentapi
  agentapi_version     = var.agentapi_version
  agentapi_subdomain   = var.agentapi_subdomain
  agentapi_port        = var.agentapi_port
  pre_install_script   = var.pre_install_script
  post_install_script  = var.post_install_script
  start_script         = local.start_script
  install_script       = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail

    echo -n '${base64encode(local.install_script)}' | base64 -d > /tmp/install.sh
    chmod +x /tmp/install.sh

    ARG_PROVIDER='amazon-q' \
    ARG_MODEL='default' \
    ARG_GOOSE_CONFIG="$(echo -n '${base64encode(local.combined_extensions)}' | base64 -d)" \
    ARG_INSTALL='${var.install_amazon_q}' \
    ARG_GOOSE_VERSION='${var.amazon_q_version}' \
    /tmp/install.sh

    echo "Extracting auth tarball..."
    PREV_DIR="$PWD"
    echo "${var.experiment_auth_tarball}" | base64 -d > /tmp/auth.tar.zst
    rm -rf ~/.local/share/amazon-q
    mkdir -p ~/.local/share/amazon-q
    cd ~/.local/share/amazon-q
    tar -I zstd -xf /tmp/auth.tar.zst
    rm /tmp/auth.tar.zst
    cd "$PREV_DIR"
    echo "Extracted auth tarball"

    if [ "${var.experiment_report_tasks}" = "true" ]; then
      echo "Configuring Amazon Q to report tasks via Coder MCP..."
      q mcp add --name coder --command "coder" --args "exp,mcp,server,--allowed-tools,coder_report_task" --env "CODER_MCP_APP_STATUS_SLUG=amazon-q" --scope global --force
      echo "Added Coder MCP server to Amazon Q configuration"
    fi

    if [ -n "${local.encoded_pre_install_script}" ]; then
      echo "Running pre-install script..."
      echo "${local.encoded_pre_install_script}" | base64 -d > /tmp/pre_install.sh
      chmod +x /tmp/pre_install.sh
      /tmp/pre_install.sh
    fi

    if [ -n "${local.encoded_post_install_script}" ]; then
      echo "Running post-install script..."
      echo "${local.encoded_post_install_script}" | base64 -d > /tmp/post_install.sh
      chmod +x /tmp/post_install.sh
      /tmp/post_install.sh
    fi

    if [ "${var.experiment_use_tmux}" = "true" ] && [ "${var.experiment_use_screen}" = "true" ]; then
      echo "Error: Both experiment_use_tmux and experiment_use_screen cannot be true simultaneously."
      echo "Please set only one of them to true."
      exit 1
    fi

    if [ "${var.experiment_use_tmux}" = "true" ]; then
      echo "Running Amazon Q in the background with tmux..."

      if ! command -v tmux >/dev/null 2>&1; then
        echo "Error: tmux is not installed. Please install tmux manually."
        exit 1
      fi

      touch "$HOME/.amazon-q.log"

      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      tmux new-session -d -s amazon-q -c "${var.folder}" "q chat --trust-all-tools | tee -a "$HOME/.amazon-q.log" && exec bash"

      tmux send-keys -t amazon-q "${local.full_prompt}"
      sleep 5
      tmux send-keys -t amazon-q Enter
    fi

    if [ "${var.experiment_use_screen}" = "true" ]; then
      echo "Running Amazon Q in the background..."

      if ! command -v screen >/dev/null 2>&1; then
        echo "Error: screen is not installed. Please install screen manually."
        exit 1
      fi

      touch "$HOME/.amazon-q.log"

      if [ ! -f "$HOME/.screenrc" ]; then
        echo "Creating ~/.screenrc and adding multiuser settings..." | tee -a "$HOME/.amazon-q.log"
        echo -e "multiuser on\nacladd $(whoami)" > "$HOME/.screenrc"
      fi

      if ! grep -q "^multiuser on$" "$HOME/.screenrc"; then
        echo "Adding 'multiuser on' to ~/.screenrc..." | tee -a "$HOME/.amazon-q.log"
        echo "multiuser on" >> "$HOME/.screenrc"
      fi

      if ! grep -q "^acladd $(whoami)$" "$HOME/.screenrc"; then
        echo "Adding 'acladd $(whoami)' to ~/.screenrc..." | tee -a "$HOME/.amazon-q.log"
        echo "acladd $(whoami)" >> "$HOME/.screenrc"
      fi
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8

      screen -U -dmS amazon-q bash -c '
        cd ${var.folder}
        q chat --trust-all-tools | tee -a "$HOME/.amazon-q.log
        exec bash
      '
      # Extremely hacky way to send the prompt to the screen session
      # This will be fixed in the future, but `amazon-q` was not sending MCP
      # tasks when an initial prompt is provided.
      screen -S amazon-q -X stuff "${local.full_prompt}"
      sleep 5
      screen -S amazon-q -X stuff "^M"
    else
      if ! command -v q >/dev/null 2>&1; then
        echo "Error: Amazon Q is not installed. Please enable install_amazon_q or install it manually."
        exit 1
      fi
    fi
  EOT
}

resource "coder_app" "amazon_q" {
  count        = var.install_agentapi ? 0 : 1
  slug         = "amazon-q"
  display_name = "Amazon Q"
  agent_id     = var.agent_id
  command      = <<-EOT
    #!/bin/bash
    set -e

    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    if [ "${var.experiment_use_tmux}" = "true" ]; then
      if tmux has-session -t amazon-q 2>/dev/null; then
        echo "Attaching to existing Amazon Q tmux session." | tee -a "$HOME/.amazon-q.log"
        tmux attach-session -t amazon-q
      else
        echo "Starting a new Amazon Q tmux session." | tee -a "$HOME/.amazon-q.log"
        tmux new-session -s amazon-q -c ${var.folder} "q chat --trust-all-tools | tee -a \"$HOME/.amazon-q.log\"; exec bash"
      fi
    elif [ "${var.experiment_use_screen}" = "true" ]; then
      if screen -list | grep -q "amazon-q"; then
        echo "Attaching to existing Amazon Q screen session." | tee -a "$HOME/.amazon-q.log"
        screen -xRR amazon-q
      else
        echo "Starting a new Amazon Q screen session." | tee -a "$HOME/.amazon-q.log"
        screen -S amazon-q bash -c 'q chat --trust-all-tools | tee -a "$HOME/.amazon-q.log"; exec bash'
      fi
    else
      cd ${var.folder}
      q chat --trust-all-tools
    fi
    EOT
  icon         = var.icon
  order        = var.order
  group        = var.group
}

resource "coder_ai_task" "amazon_q" {
  count = var.install_agentapi ? 1 : 0
  sidebar_app {
    id = module.agentapi.coder_app_agentapi_web.id
  }
}
