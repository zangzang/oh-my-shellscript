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

MODULE_ID="dev.gradle"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "🧪 Gradle 설치 테스트 중..."

# Gradle 버전 확인
if ! command -v gradle &> /dev/null; then
    echo "❌ Gradle이 설치되지 않았습니다."
    exit 1
fi

GRADLE_VERSION=$(gradle --version | grep "Gradle" | head -n 1)
echo "✅ Gradle 버전: $GRADLE_VERSION"

# 기존 파일 정리
if [[ -d "hello-gradle" ]] || [[ -f "settings.gradle" ]]; then
    echo "🧹 기존 프로젝트 파일 정리 중..."
    rm -rf hello-gradle settings.gradle* gradle* build.gradle* .gradle
fi

# Gradle 프로젝트 생성
echo "📦 Gradle 프로젝트 생성 중..."
gradle init --type java-application --dsl groovy --test-framework junit --project-name hello-gradle --package com.example --no-split-project --no-incubating --use-defaults

cd hello-gradle

# 빌드 실행
echo "🔨 빌드 중..."
gradle build -q

# 실행
echo "🚀 실행 중..."
OUTPUT=$(gradle run -q --console=plain)
echo "✅ 출력: $OUTPUT"

if [[ "$OUTPUT" == "Hello World!"* ]]; then
    echo "✅ Gradle 테스트 통과!"
    echo "📁 테스트 파일 위치: $TEST_DIR/hello-gradle"
    exit 0
else
    echo "❌ Gradle 테스트 실패"
    exit 1
fi
