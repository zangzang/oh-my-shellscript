#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing fetch tools..."
install_packages curl gawk zstd

echo "✅ Fetch tools installation complete"
