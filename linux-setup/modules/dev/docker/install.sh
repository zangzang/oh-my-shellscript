#!/bin/bash
set -e
if command -v docker &>/dev/null; then
    echo "Docker 이미 설치됨."
    exit 0
fi

echo "Docker 설치 중..."
if curl -fsSL https://get.docker.com | sh; then
    sudo usermod -aG docker "$USER"
    echo "Docker 설치 완료. 그룹 적용을 위해 재로그인이 필요할 수 있습니다."
else
    echo "Docker 설치 실패"
    exit 1
fi
