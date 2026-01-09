#!/bin/bash
set -e

echo "🧪 .NET 설치 테스트 중..."

# .NET PATH 설정
export PATH="$HOME/.dotnet:$PATH"

# .NET이 설치되어 있는지 확인
if ! command -v dotnet &>/dev/null; then
    echo "❌ dotnet 명령을 찾을 수 없습니다."
    exit 1
fi

# 버전 확인
echo "✅ .NET 버전: $(dotnet --version)"

# 테스트 디렉토리 생성 (linux-setup/test/dev.dotnet/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.dotnet"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 기존 프로젝트 정리
if [[ -d "HelloWorld" ]]; then
    echo "🧹 기존 프로젝트 디렉터리 정리 중..."
    rm -rf HelloWorld
fi

echo "📝 Hello World 콘솔 앱 생성 중..."
if ! dotnet new console -n HelloWorld -o HelloWorld &>/dev/null; then
    echo "❌ 프로젝트 생성 실패"
    exit 1
fi

cd HelloWorld

echo "🚀 실행 중..."
OUTPUT=$(dotnet run 2>&1)

cd ~

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ .NET 테스트 통과!"
    echo "📁 테스트 프로젝트 위치: $TEST_DIR/HelloWorld"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 프로젝트 위치: $TEST_DIR/HelloWorld"
    exit 1
fi
