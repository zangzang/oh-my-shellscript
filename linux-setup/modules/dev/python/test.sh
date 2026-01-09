#!/bin/bash
set -e

echo "🧪 Python 설치 테스트 중..."

# Python이 설치되어 있는지 확인
if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
    echo "❌ python 명령을 찾을 수 없습니다."
    exit 1
fi

# Python 명령 결정 (python3 우선)
PYTHON_CMD="python3"
if ! command -v python3 &>/dev/null; then
    PYTHON_CMD="python"
fi

# 버전 확인
echo "✅ Python 버전: $($PYTHON_CMD --version)"

# 테스트 디렉토리 생성 (linux-setup/test/dev.python/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.python"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"

# Hello World 실행
echo "🚀 실행 중..."
OUTPUT=$($PYTHON_CMD -c "print('Hello World from Python!')" 2>&1)

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ Python 테스트 통과!"
    echo "📁 테스트 디렉토리: $TEST_DIR"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 디렉토리: $TEST_DIR"
    exit 1
fi
