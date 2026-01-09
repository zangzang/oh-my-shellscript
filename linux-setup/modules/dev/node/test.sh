#!/bin/bash
set -e

echo "🧪 Node.js 설치 테스트 중..."

# NVM 초기화
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Node.js가 설치되어 있는지 확인
if ! command -v node &>/dev/null; then
    echo "❌ node 명령을 찾을 수 없습니다."
    exit 1
fi

# 버전 확인
echo "✅ Node.js 버전: $(node --version)"
echo "✅ npm 버전: $(npm --version)"

# 테스트 디렉토리 생성 (linux-setup/test/dev.node/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)/test"
MODULE_ID="dev.node"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📝 hello.js 생성 중..."
cat > hello.js << 'EOF'
console.log('Hello World from Node.js!');
EOF

echo "🚀 실행 중..."
OUTPUT=$(node hello.js 2>&1)

cd ~

# 결과 확인
if echo "$OUTPUT" | grep -q "Hello World"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ Node.js 테스트 통과!"
    echo "📁 테스트 파일 위치: $TEST_DIR/hello.js"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 파일 위치: $TEST_DIR/hello.js"
    exit 1
fi
