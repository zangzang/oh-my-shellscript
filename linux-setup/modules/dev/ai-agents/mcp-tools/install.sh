#!/bin/bash
set -e

echo "Installing MCP Tools..."

# Install uv (fast python package installer, recommended for MCP)
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env 2>/dev/null || true
fi

# Python MCP SDK
if command -v pip &> /dev/null; then
    echo "Installing python mcp sdk..."
    pip install -U mcp
fi

# Node MCP SDK (if relevant/available)
if command -v npm &> /dev/null; then
    echo "Installing Node.js MCP SDK..."
    npm install -g @modelcontextprotocol/sdk
fi

echo "MCP Tools setup complete."
