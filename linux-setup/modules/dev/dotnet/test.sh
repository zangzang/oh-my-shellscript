#!/bin/bash
set -e

echo "🧪 .NET 설치 테스트 중..."

# .NET PATH 설정
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

if ! command -v dotnet &>/dev/null; then
    echo "❌ dotnet 명령을 찾을 수 없습니다."
    exit 1
fi

echo "✅ .NET 버전: $(dotnet --version)"

# 테스트 디렉토리 생성
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="/tmp/dotnet-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 Hello World 콘솔 앱 생성 중..."
dotnet new console -n HelloWorld >/dev/null 2>&1

cd HelloWorld

echo "🚀 빌드 및 실행 중..."
# --nologo 옵션으로 불필요한 출력 제거
OUTPUT=$(dotnet run --nologo 2>&1 || true)

# 결과 확인 (대소문자 구분 없이 hello 검색)
if echo "$OUTPUT" | grep -qi "hello"; then
    echo "✅ 출력: $(echo "$OUTPUT" | head -n 1)"
    echo "✅ .NET 테스트 통과!"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "❌ 실행 결과 확인 실패"
    echo "📝 실제 출력: $OUTPUT"
    rm -rf "$TEST_DIR"
    exit 1
fi