#!/bin/bash
set -e
echo "Installing build tools..."
sudo apt install -y \
    curl wget git unzip zip build-essential \
    software-properties-common apt-transport-https ca-certificates gnupg \
    cmake pkg-config autoconf automake libtool
