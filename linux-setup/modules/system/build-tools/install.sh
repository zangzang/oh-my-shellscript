#!/bin/bash
set -e

# Source library
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# path to lib/distro.sh: modules/system/build-tools -> ../../.. -> lib
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Installing build tools..."
install_packages \
    curl wget git unzip zip build-essential \
    software-properties-common apt-transport-https ca-certificates gnupg \
    cmake pkg-config autoconf automake libtool
