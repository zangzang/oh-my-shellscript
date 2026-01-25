#!/bin/bash
set -e

# Install MCP Playwright Server
echo "Installing MCP Playwright Server..."
# Installing browser binaries is also needed usually
npm install -g @modelcontextprotocol/server-playwright
npx playwright install --with-deps chromium
