#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

if ! command -v fastfetch &>/dev/null; then
echo "Installing Fastfetch..."
# ... (download logic)
echo "Could not find Fastfetch download URL."
# ...
echo "Fastfetch is already installed."
echo "Fastfetch installation complete."
