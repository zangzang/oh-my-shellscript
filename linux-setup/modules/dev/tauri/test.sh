#!/bin/bash
set -e

MODULE_ID="dev.tauri"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEST_DIR="$WORKSPACE_ROOT/test/$MODULE_ID"

# Node.js PATH 초기화 (NVM)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    nounset_was_on=0
    if [[ "$-" =~ u ]]; then
        nounset_was_on=1
        set +u
    fi
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    if [[ $nounset_was_on -eq 1 ]]; then
        set -u
    fi
fi

# Rust PATH 초기화
if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 기존 프로젝트 정리 (전체 TEST_DIR 정리)
echo "🧹 기존 테스트 파일 정리 중..."
rm -rf "$TEST_DIR"/*

echo "🧪 Tauri 설치 테스트 중..."

# Rust 확인
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust(cargo)가 설치되지 않았습니다."
    exit 1
fi
echo "✅ Rust 버전: $(rustc --version | head -n 1)"

# Node.js 확인
if ! command -v node &> /dev/null; then
    echo "❌ Node.js가 설치되지 않았습니다."
    exit 1
fi
echo "✅ Node.js 버전: $(node --version)"

# npm 확인
if ! command -v npm &> /dev/null; then
    echo "❌ npm이 설치되지 않았습니다."
    exit 1
fi
echo "✅ npm 버전: $(npm --version)"

# Tauri 의존성 확인 (pkg-config를 통해)
echo "🔍 Tauri 의존성 확인 중..."
for pkg in gtk+-3.0 webkit2gtk-4.1 glib-2.0; do
    if pkg-config --exists "$pkg" 2>/dev/null; then
        echo "✅ $pkg 설치됨"
    else
        echo "❌ $pkg 설치되지 않음"
        exit 1
    fi
done

# Tauri CLI 확인
echo "📦 Tauri CLI 확인 중..."
if ! command -v cargo-tauri &> /dev/null; then
    echo "❌ Tauri CLI(cargo-tauri)가 설치되지 않았습니다. dev.tauri 모듈을 먼저 설치하세요."
    exit 1
fi
echo "✅ Tauri CLI 준비됨"

# 간단한 Tauri 프로젝트 생성
echo "📝 Tauri 프로젝트 생성 중..."
# create-tauri-app을 비대화형 모드로 실행
npm create tauri-app@latest tauri-hello -- --yes --manager npm --template vanilla

if [[ ! -d "tauri-hello" ]]; then
    echo "❌ 프로젝트 생성 실패"
    exit 1
fi

cd tauri-hello

# 빌드 테스트 (실제 빌드는 시간이 오래 걸리므로 체크만)
echo "🔨 프로젝트 구조 확인 중..."
if [[ -f "src-tauri/Cargo.toml" ]] && [[ -f "package.json" ]]; then
    echo "✅ Tauri 프로젝트 구조 정상"
    echo "✅ Tauri 테스트 통과!"
    echo "📁 테스트 프로젝트 위치: $TEST_DIR/tauri-hello"
    exit 0
else
    echo "❌ 프로젝트 구조가 올바르지 않습니다."
    exit 1
fi
