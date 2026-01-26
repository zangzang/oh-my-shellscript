#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing dev libraries..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    install_packages \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
        libffi-dev liblzma-dev libgdbm-dev libnss3-dev
elif [[ "$OS_ID" == "fedora" ]]; then
    install_packages \
        openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel \
        ncurses-devel xz tk-devel libxml2-devel xmlsec1-devel \
        libffi-devel xz-devel gdbm-devel nss-devel
else
    echo "⚠️ Unsupported OS: $OS_ID"
    exit 1
fi

echo "✅ Dev libraries installation complete"
