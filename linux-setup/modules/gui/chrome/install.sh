#!/bin/bash
set -e
if command -v google-chrome &>/dev/null; then
    echo "Chrome 이미 설치됨."
else
    echo "Chrome 설치 중..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    echo "Chrome 설치 완료"
fi
