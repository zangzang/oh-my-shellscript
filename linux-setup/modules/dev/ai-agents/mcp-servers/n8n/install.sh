#!/bin/bash
set -e

# Install MCP n8n Server
echo "Installing MCP n8n Server..."
# Note: This assumes a community package or similar exists. 
# If not, it falls back to a warning.
if npm view mcp-server-n8n version &> /dev/null; then
    npm install -g mcp-server-n8n
else
    echo "⚠️  mcp-server-n8n package not found in registry."
    echo "Please configure n8n manually or use the OpenAPI MCP server to connect to n8n."
fi
