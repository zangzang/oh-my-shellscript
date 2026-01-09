#!/bin/bash
set -e

# SDKMAN 환경 초기화
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    nounset_was_on=0
    if [[ "$-" =~ u ]]; then
        nounset_was_on=1
        set +u
    fi
    # shellcheck disable=SC1091
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    if [[ $nounset_was_on -eq 1 ]]; then
        set -u
    fi
fi

MODULE_ID="dev.maven"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "🧪 Maven 설치 테스트 중..."

# Maven 버전 확인
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven이 설치되지 않았습니다."
    exit 1
fi

MVN_VERSION=$(mvn --version | head -n 1)
echo "✅ Maven 버전: $MVN_VERSION"

# 기존 프로젝트 디렉터리 정리
if [[ -d "hello-maven" ]]; then
    echo "🧹 기존 프로젝트 디렉터리 정리 중..."
    rm -rf hello-maven
fi

# Maven 프로젝트 생성
echo "📦 Maven 프로젝트 생성 중..."
mvn archetype:generate \
    -DgroupId=com.example \
    -DartifactId=hello-maven \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DarchetypeVersion=1.4 \
    -DinteractiveMode=false

cd hello-maven

# 빌드 실행
echo "🔨 빌드 중..."
mvn clean package -q

# 실행
echo "🚀 실행 중..."
OUTPUT=$(java -cp target/hello-maven-1.0-SNAPSHOT.jar com.example.App)
echo "✅ 출력: $OUTPUT"

if [[ "$OUTPUT" == "Hello World!"* ]]; then
    echo "✅ Maven 테스트 통과!"
    echo "📁 테스트 파일 위치: $TEST_DIR/hello-maven"
    exit 0
else
    echo "❌ Maven 테스트 실패"
    exit 1
fi
