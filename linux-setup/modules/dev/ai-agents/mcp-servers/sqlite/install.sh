#!/bin/bash
set -e

# Install MCP SQLite Server
echo "Installing MCP SQLite Server..."

if command -v npm &> /dev/null; then
    npm install -g @modelcontextprotocol/server-sqlite
else
    echo "npm not found. Please install Node.js and npm."
    exit 1
fi
