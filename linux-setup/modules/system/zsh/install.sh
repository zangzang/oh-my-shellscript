#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os
echo "Installing Zsh..."
install_packages zsh yakuake


# Change default shell to Zsh
# ...
echo "⚠️  Default shell changed to Zsh (Requires re-login)"
# ...
echo "Zsh installation complete"
