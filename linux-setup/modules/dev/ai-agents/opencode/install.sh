#!/bin/bash
set -e

# Install Open Code
if ! command -v opencode &> /dev/null; then
    echo "Installing Open Code..."
    curl -fsSL https://opencode.ai/install | bash
else
    echo "Open Code is already installed."
fi
