#!/bin/bash
set -e

echo "🧪 Rust 설치 테스트 중..."

# Cargo PATH 설정
export PATH="$HOME/.cargo/bin:$PATH"

# Rust가 설치되어 있는지 확인
if ! command -v cargo &>/dev/null; then
    echo "❌ cargo 명령을 찾을 수 없습니다."
    exit 1
fi

if ! command -v rustc &>/dev/null; then
    echo "❌ rustc 명령을 찾을 수 없습니다."
    exit 1
fi

# 버전 확인
echo "✅ Rust 버전: $(rustc --version)"
echo "✅ Cargo 버전: $(cargo --version)"

# 테스트 디렉토리 생성 (linux-setup/test/dev.rust/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.rust"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 기존 프로젝트 정리
if [[ -d "hello" ]]; then
    echo "🧹 기존 프로젝트 디렉터리 정리 중..."
    rm -rf hello
fi

echo "📝 Cargo 프로젝트 생성 중..."
if ! cargo new hello --bin --quiet; then
    echo "❌ 프로젝트 생성 실패"
    exit 1
fi

cd hello

echo "🚀 실행 중..."
OUTPUT=$(cargo run --quiet 2>&1)

cd ~

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ Rust 테스트 통과!"
    echo "📁 테스트 프로젝트 위치: $TEST_DIR/hello"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 프로젝트 위치: $TEST_DIR/hello"
    exit 1
fi
