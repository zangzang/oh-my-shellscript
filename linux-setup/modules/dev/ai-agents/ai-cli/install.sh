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
    VARIANT="gemini-cli"
fi

PACKAGE=""
COMMAND=""
NAME=""

case "$VARIANT" in
    gemini-cli)
        PACKAGE="@google/gemini-cli"
        COMMAND="gemini"
        NAME="Gemini CLI"
        ;;
    claude-code)
        PACKAGE="@anthropic-ai/claude-code"
        COMMAND="claude"
        NAME="Claude Code"
        ;;
    opencode)
        PACKAGE="opencode-ai"
        COMMAND="opencode"
        NAME="OpenCode Agent"
        ;;
    *)
        ui_log_error "Unknown AI CLI variant: $VARIANT"
        exit 1
        ;;
esac

if ! command -v "$COMMAND" &> /dev/null; then
    ui_log_info "Installing $NAME..."
    npm_install_g "$PACKAGE"
else
    ui_log_info "$NAME is already installed."
fi
