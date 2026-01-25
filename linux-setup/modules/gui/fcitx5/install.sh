#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing Fcitx5 and Korean configuration..."
# ...
echo "Fcitx5 installation complete. Please re-login to apply changes."
