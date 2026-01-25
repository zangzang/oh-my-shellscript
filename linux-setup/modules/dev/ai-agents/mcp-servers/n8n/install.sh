#!/bin/bash
set -e

# Install MCP n8n Server
echo "Installing MCP n8n Server..."
# Note: Official mcp-server-n8n does not exist. Using community package.
if command -v npm &> /dev/null; then
    npm install -g @leonardsellem/n8n-mcp-server
else
    echo "npm not found. Please install Node.js and npm."
    exit 1
fi
