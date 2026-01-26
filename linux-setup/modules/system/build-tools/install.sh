#!/bin/bash
set -e

# Source library
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# path to lib/distro.sh: modules/system/build-tools -> ../../.. -> lib
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing build tools..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    install_packages \
        curl wget git unzip zip build-essential \
        software-properties-common apt-transport-https ca-certificates gnupg \
        cmake pkg-config autoconf automake libtool
elif [[ "$OS_ID" == "fedora" ]]; then
    # Fedora uses different package names
    install_packages \
        curl wget git unzip zip \
        dnf-plugins-core ca-certificates gnupg2 \
        cmake pkgconf-pkg-config autoconf automake libtool \
        gcc gcc-c++ make
    # Install development tools group
    sudo dnf groupinstall -y "Development Tools" || true
else
    echo "⚠️ Unsupported OS: $OS_ID"
    exit 1
fi

echo "✅ Build tools installation complete"
