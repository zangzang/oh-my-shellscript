#!/bin/bash
set -e

if command -v oh-my-posh &>/dev/null; then
    echo "Oh My Posh 이미 설치됨 ($(oh-my-posh version))"
    exit 0
fi

echo "Oh My Posh 설치 중..."
sudo wget -q https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
sudo chmod +x /usr/local/bin/oh-my-posh

# 테마 디렉토리 생성 및 Catppuccin Mocha 테마 다운로드
OMP_THEME_DIR="$HOME/.config/oh-my-posh"
mkdir -p "$OMP_THEME_DIR"

if [ ! -f "$OMP_THEME_DIR/catppuccin_mocha.omp.json" ]; then
    echo "Catppuccin Mocha 테마 다운로드 중..."
    wget -q https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json \
        -O "$OMP_THEME_DIR/catppuccin_mocha.omp.json"
fi

echo "Oh My Posh 설치 완료"
