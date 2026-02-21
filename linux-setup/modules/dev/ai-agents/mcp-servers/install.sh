#!/bin/bash
set -e

# Load Library
if ! command -v ui_log_info &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

VARIANT="$1"
if [[ -z "$VARIANT" ]]; then
    VARIANT="filesystem"
fi

PACKAGE=""
case "$VARIANT" in
    filesystem)
        PACKAGE="@modelcontextprotocol/server-filesystem"
        ;;
    github)
        PACKAGE="@modelcontextprotocol/server-github"
        ;;
    postgres)
        PACKAGE="@modelcontextprotocol/server-postgres"
        ;;
    sqlite)
        PACKAGE="@modelcontextprotocol/server-sqlite"
        ;;
    brave-search)
        PACKAGE="@modelcontextprotocol/server-brave-search"
        ;;
    memory)
        PACKAGE="@modelcontextprotocol/server-memory"
        ;;
    playwright)
        PACKAGE="@playwright/mcp"
        ;;
    puppeteer)
        PACKAGE="@modelcontextprotocol/server-puppeteer"
        ;;
    n8n)
        PACKAGE="@n8n/mcp"
        ;;
    *)
        ui_log_error "Unknown MCP server variant: $VARIANT"
        exit 1
        ;;
esac

ui_log_info "Installing MCP Server variant: $VARIANT"
ui_log_info "Package: $PACKAGE"
npm install -g "$PACKAGE" || ui_log_warn "Package install failed or not available: $PACKAGE"
ui_log_success "MCP Server ($VARIANT) installation complete"
