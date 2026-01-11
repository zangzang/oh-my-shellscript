#!/bin/bash
set -e

echo "🧪 Docker 설치 테스트 중..."

# Docker가 설치되어 있는지 확인
if ! command -v docker &>/dev/null; then
    echo "❌ docker 명령을 찾을 수 없습니다."
    exit 1
fi

# 버전 확인
echo "✅ Docker 버전: $(docker --version)"

# Docker 데몬이 실행 중인지 확인 (sudo 사용 - 그룹 권한 적용 전)
if ! sudo docker info &>/dev/null; then
    echo "❌ Docker 데몬이 실행되고 있지 않습니다."
    echo "   'sudo systemctl start docker' 명령으로 시작하세요."
    exit 1
fi

# 테스트 디렉토리 생성 (linux-setup/test/dev.docker/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.docker"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"

# Hello World 컨테이너 실행 (sudo 사용 - 그룹 권한 적용 전)
echo "🚀 hello-world 컨테이너 실행 중..."
OUTPUT=$(sudo docker run --rm hello-world 2>&1)

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello from Docker"; then
    echo "✅ Docker 테스트 통과!"
    echo "📁 테스트 디렉토리: $TEST_DIR"
    exit 0
else
    echo "❌ 예상치 못한 출력"
    echo "$OUTPUT"
    echo "📁 테스트 디렉토리: $TEST_DIR"
    exit 1
fi
