#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing CLI tools..."
# 'bat' in Fedora is 'bat', in Ubuntu it's 'bat' (often mapped to batcat, but package name is bat usually or needs mapping)
# 'fd-find' -> Ubuntu: fd-find, Fedora: fd-find
install_packages \
    jq tree htop btop ncdu mc \
    bat ripgrep fd-find eza fzf \
    vim nano
