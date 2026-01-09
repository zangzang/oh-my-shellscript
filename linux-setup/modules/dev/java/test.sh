#!/bin/bash
set -e

echo "🧪 Java 설치 테스트 중..."

# SDKMAN 초기화
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    set +u
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    set -u
fi

# Java가 설치되어 있는지 확인
if ! command -v java &>/dev/null; then
    echo "❌ java 명령을 찾을 수 없습니다."
    exit 1
fi

if ! command -v javac &>/dev/null; then
    echo "❌ javac 명령을 찾을 수 없습니다."
    exit 1
fi

# 버전 확인
echo "✅ Java 버전: $(java -version 2>&1 | head -n 1)"
echo "✅ Javac 버전: $(javac -version 2>&1)"

# 테스트 디렉토리 생성 (linux-setup/test/dev.java/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.java"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 Hello.java 생성 중..."
cat > Hello.java << 'EOF'
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello World from Java!");
    }
}
EOF

echo "🔨 컴파일 중..."
if ! javac Hello.java; then
    echo "❌ 컴파일 실패"
    exit 1
fi

echo "🚀 실행 중..."
OUTPUT=$(java Hello 2>&1)

cd ~

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ Java 테스트 통과!"
    echo "📁 테스트 파일 위치: $TEST_DIR/Hello.java"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 파일 위치: $TEST_DIR/Hello.java"
    exit 1
fi
