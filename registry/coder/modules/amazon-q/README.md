---
display_name: Amazon Q
description: Run Amazon Q in your workspace to access Amazon's AI coding assistant.
icon: ../../../../.icons/amazon-q.svg
verified: true
tags: [agent, ai, aws, amazon-q]
---

# Amazon Q

Run [Amazon Q](https://aws.amazon.com/q/) in your workspace to access Amazon's AI coding assistant. This module installs and launches Amazon Q, with support for background operation, task reporting, custom pre/post install scripts, and integration with Coder Tasks and AgentAPI for enhanced web chat interface.

```tf
module "amazon-q" {
  source   = "registry.coder.com/coder/amazon-q/coder"
  version  = "1.1.2"
  agent_id = coder_agent.example.id

  # Required: see below for how to generate
  experiment_auth_tarball = var.amazon_q_auth_tarball
}
```

![Amazon-Q in action](../../.images/amazon-q.png)

## Prerequisites

- You must generate an authenticated Amazon Q tarball on another machine:
  ```sh
  cd ~/.local/share/amazon-q && tar -c . | zstd | base64 -w 0
  ```
  Paste the result into the `experiment_auth_tarball` variable.
- To run in the background, your workspace must have `screen` or `tmux` installed.

<details>
<summary><strong>How to generate the Amazon Q auth tarball (step-by-step)</strong></summary>

**1. Install and authenticate Amazon Q on your local machine:**

- Download and install Amazon Q from the [official site](https://aws.amazon.com/q/developer/).
- Run `q login` and complete the authentication process in your terminal.

**2. Locate your Amazon Q config directory:**

- The config is typically stored at `~/.local/share/amazon-q`.

**3. Generate the tarball:**

- Run the following command in your terminal:
  ```sh
  cd ~/.local/share/amazon-q
  tar -c . | zstd | base64 -w 0
  ```

**4. Copy the output:**

- The command will output a long string. Copy this entire string.

**5. Paste into your Terraform variable:**

- Assign the string to the `experiment_auth_tarball` variable in your Terraform configuration, for example:
  ```tf
  variable "amazon_q_auth_tarball" {
    type    = string
    default = "PASTE_LONG_STRING_HERE"
  }

## Examples

### Run in the background and report tasks (Experimental)

> This functionality is in early access as of Coder v2.21 and is still evolving.
> For now, we recommend testing it in a demo or staging environment,
> rather than deploying to production
>
> Learn more in [the Coder documentation](https://coder.com/docs/tutorials/ai-agents)
>
> Join our [Discord channel](https://discord.gg/coder) or
> [contact us](https://coder.com/contact) to get help or share feedback.

```tf
variable "amazon_q_auth_tarball" {
  type        = string
  description = "The base64-encoded Amazon Q authentication tarball"
  sensitive   = true
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.0.15"
  agent_id = coder_agent.example.id
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = ""
  description = "Write a prompt for Amazon Q"
  mutable     = true
}

# Set the prompt for Amazon Q via environment variables
resource "coder_agent" "main" {
  # ...
  env = {
    CODER_MCP_AMAZON_Q_TASK_PROMPT = data.coder_parameter.ai_prompt.value
    CODER_MCP_APP_STATUS_SLUG      = "amazon-q"
  }
}

module "amazon-q" {
  count              = data.coder_workspace.me.start_count
  source             = "registry.coder.com/coder/amazon-q/coder"
  version            = "1.1.2"
  agent_id           = coder_agent.example.id
  auth_tarball       = var.amazon_q_auth_tarball

  # Enable experimental features
  experiment_report_tasks = true
}
```

## Run standalone

Run Amazon Q as a standalone app in your workspace. This will install Amazon Q and run it without any task reporting to the Coder UI.

```tf
module "amazon-q" {
  source        = "registry.coder.com/coder/amazon-q/coder"
  version       = "1.1.2"
  agent_id      = coder_agent.example.id
  auth_tarball  = var.amazon_q_auth_tarball

  # Icon is not available in Coder v2.20 and below, so we'll use a custom icon URL
  icon = "https://raw.githubusercontent.com/coder/registry/main/.icons/amazon-q.svg"
}
```

## Troubleshooting

The module will create log files in the workspace's `~/.amazon-q-module` directory. If you run into any issues, look at them for more information. Q runs in the foreground.
- For more details, see the [main.tf](./main.tf) source.

## Using with Coder Tasks Template

To use Amazon Q with the Coder Tasks template:

1. First, deploy the [Tasks on Docker](https://registry.coder.com/templates/coder-labs/tasks-docker) template
2. Replace the Claude Code module with the Amazon Q module in the template
3. Add your Amazon Q authentication tarball as a parameter.

Example configuration in the Tasks template:

```tf
variable "amazon_q_auth_tarball" {
  type        = string
  description = "The base64-encoded Amazon Q authentication tarball"
  sensitive   = true
}

module "amazon-q" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/coder/amazon-q/coder"
  version             = "1.1.2"
  agent_id            = coder_agent.main.id
  auth_tarball        = var.amazon_q_auth_tarball
  folder              = "/home/coder/projects"
  install_amazon_q    = true
  amazon_q_version    = "latest"
  order               = 999

  experiment_post_install_script = data.coder_parameter.setup_script.value

  # This enables Coder Tasks
  experiment_report_tasks = true
}
```

## Tasks Integration

When using AgentAPI (enabled by default), Amazon Q will automatically report task progress to the Coder Tasks UI. This provides real-time visibility into what Amazon Q is working on and its current status.
## AgentAPI Web Interface

When AgentAPI is enabled, a web interface is provided for interacting with Amazon Q through a chat interface. This interface supports all the features of the command-line version while providing a more user-friendly experience.
