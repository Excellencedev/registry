#!/bin/bash
set -e

# This script starts Amazon Q with AgentAPI integration

# Set environment variables for proper UTF-8 support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Change to the working directory
cd "${ARG_WORKDIR}"

# Start Amazon Q with trust-all-tools flag to allow MCP extensions
exec q chat --trust-all-tools
