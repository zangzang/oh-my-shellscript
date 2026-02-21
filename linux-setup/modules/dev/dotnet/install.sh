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

# Install .NET
if ! curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel "$VERSION" --install-dir "$HOME/.dotnet" --no-path; then
    echo "Failed to install .NET"
    exit 1
fi

# Add to PATH (if not exists)
# .bashrc 설정
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "DOTNET_ROOT\|\.dotnet" "$HOME/.bashrc"; then
        cat <<'BASHRC_DOTNET' >> ~/.bashrc

# .NET SDK
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
BASHRC_DOTNET
        echo "✓ .bashrc configured"
    fi
fi

# .zshrc 설정
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "DOTNET_ROOT\|\.dotnet" "$HOME/.zshrc"; then
        cat <<'ZSHRC_DOTNET' >> ~/.zshrc

# .NET SDK
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
ZSHRC_DOTNET
        echo "✓ .zshrc configured"
    fi
fi

echo ".NET SDK $VERSION installation complete"