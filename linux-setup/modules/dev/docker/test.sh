#!/bin/bash
set -e

echo "🧪 Docker 설치 테스트 중..."

if ! command -v docker &>/dev/null; then
    echo "❌ docker 명령을 찾을 수 없습니다."
    exit 1
fi

# WSL 2 환경 확인
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

# 버전 확인
VERSION=$(docker --version)
echo "✅ Docker 버전: $VERSION"

# 데몬 실행 확인
if ! docker ps >/dev/null 2>&1; then
    if [ "$IS_WSL" = true ]; then
        echo "ℹ️  WSL 2 환경이 감지되었습니다."
        echo "   Windows의 Docker Desktop 설정에서 이 배포판(WSL Integration)을 활성화했는지 확인하세요."
    else
        echo "❌ Docker 데몬이 실행되고 있지 않습니다."
        echo "   'sudo systemctl start docker' 명령으로 시작하세요."
    fi
    exit 1
fi

echo "✅ Docker 데몬 실행 중"
echo "✅ Docker 테스트 통과!"
exit 0