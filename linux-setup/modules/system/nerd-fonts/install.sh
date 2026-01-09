#!/bin/bash
set -e

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if [ -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
    echo "Meslo Nerd Font 이미 설치됨"
    exit 0
fi

echo "Meslo Nerd Font 다운로드 중..."
base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
wget -qP "$FONT_DIR" "$base_url/MesloLGS%20NF%20Regular.ttf"
wget -qP "$FONT_DIR" "$base_url/MesloLGS%20NF%20Bold.ttf"
wget -qP "$FONT_DIR" "$base_url/MesloLGS%20NF%20Italic.ttf"
wget -qP "$FONT_DIR" "$base_url/MesloLGS%20NF%20Bold%20Italic.ttf"

echo "폰트 캐시 업데이트 중..."
fc-cache -fv >/dev/null 2>&1

echo "Meslo Nerd Font 설치 완료"
