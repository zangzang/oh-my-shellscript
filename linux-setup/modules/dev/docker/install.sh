#!/bin/bash
set -e
if command -v docker &>/dev/null; then
    echo "Docker 이미 설치됨."
    exit 0
fi

echo "Docker 설치 중..."
if curl -fsSL https://get.docker.com | sh; then
    # Docker 서비스 시작 및 자동 시작 활성화
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 현재 사용자를 docker 그룹에 추가
    sudo usermod -aG docker "$USER"
    
    echo "Docker 설치 완료."
    echo "✅ Docker 서비스 시작됨"
    echo "⚠️  docker 명령을 sudo 없이 사용하려면 재로그인이 필요합니다."
else
    echo "Docker 설치 실패"
    exit 1
fi
