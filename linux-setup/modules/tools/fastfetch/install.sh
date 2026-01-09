#!/bin/bash
set -e
if ! command -v fastfetch &>/dev/null; then
    echo "Fastfetch 설치 중..."
    FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64.deb")) | .browser_download_url')
    if [ -n "$FASTFETCH_URL" ]; then
        wget -q "$FASTFETCH_URL" -O /tmp/fastfetch.deb
        sudo apt install -y /tmp/fastfetch.deb
        rm /tmp/fastfetch.deb
    else
        echo "Fastfetch 다운로드 URL을 찾을 수 없습니다."
        exit 1
    fi
else
    echo "Fastfetch 이미 설치됨."
fi
