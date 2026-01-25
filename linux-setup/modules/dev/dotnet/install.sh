#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

VERSION="$1"

if [[ -z "$VERSION" ]]; then
    VERSION="9"
fi

# Normalize version: "8" -> "8.0", "9" -> "9.0", etc
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    VERSION="${VERSION}.0"
fi

echo "Installing .NET SDK $VERSION..."

# Check dependencies
echo "📦 Checking essential dependencies..."
install_packages curl gawk

# Install .NET
if ! curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel "$VERSION" --install-dir "$HOME/.dotnet" --no-path; then
    echo "Failed to install .NET"
    exit 1
fi

# Add to PATH (if not exists)
if ! grep -q '\.dotnet' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.zshrc"
fi
if ! grep -q '\.dotnet' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.bashrc"
fi

echo ".NET SDK $VERSION installation complete"