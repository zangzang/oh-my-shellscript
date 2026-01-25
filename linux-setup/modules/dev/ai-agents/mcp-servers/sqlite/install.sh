#!/bin/bash
set -e

# Install MCP SQLite Server
echo "Installing MCP SQLite Server..."

if command -v uv &> /dev/null; then
    uv tool install mcp-server-sqlite
else
    pip install mcp-server-sqlite
fi
