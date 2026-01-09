#!/bin/bash
set -e

if command -v zsh &>/dev/null; then
    echo "Zsh 이미 설치됨 ($(zsh --version))"
    exit 0
fi

echo "Zsh 및 Yakuake 설치 중..."
sudo apt install -y zsh yakuake

# 기본 쉘을 Zsh로 변경
if [ "$(basename "$SHELL")" != "zsh" ]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
    echo "⚠️  기본 쉘이 Zsh로 변경됨 (재로그인 필요)"
fi

echo "Zsh 설치 완료"
