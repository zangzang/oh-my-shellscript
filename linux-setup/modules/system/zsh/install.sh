#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os
echo "Installing Zsh..."
install_packages zsh yakuake


# 기본 쉘을 Zsh로 변경
if [ "$(basename "$SHELL")" != "zsh" ]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
    echo "⚠️  기본 쉘이 Zsh로 변경됨 (재로그인 필요)"
fi

echo "Zsh 설치 완료"
