#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

if command -v google-chrome &>/dev/null; then
    echo "Chrome 이미 설치됨."
else
    echo "Chrome 설치 중..."
    
    if [ "$OS_ID" == "fedora" ]; then
        sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    else
        wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y ./google-chrome-stable_current_amd64.deb
        rm google-chrome-stable_current_amd64.deb
    fi
    echo "Chrome 설치 완료"
fi
