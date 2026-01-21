#!/bin/bash
set -e

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "🦋 Flutter SDK 설치 중..."

# 1. Linux Flutter 필수 의존성 설치
PKGS=("curl" "git" "unzip" "xz-utils")
if [[ "$OS_ID" == "fedora" ]]; then
    PKGS+=("mesa-libGLU" "clang" "cmake" "ninja-build" "pkg-config" "gtk3-devel")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    PKGS+=("libglu1-mesa" "clang" "cmake" "ninja-build" "pkg-config" "libgtk-3-dev")
fi

install_packages "${PKGS[@]}"

# 2. Flutter SDK 다운로드 (Git Clone)
FLUTTER_ROOT="$HOME/flutter"
if [[ -d "$FLUTTER_ROOT" ]]; then
    echo "✅ Flutter SDK가 이미 존재합니다: $FLUTTER_ROOT"
    echo "   업데이트 확인 중..."
    cd "$FLUTTER_ROOT"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git pull
    else
        echo "⚠️  $FLUTTER_ROOT 디렉토리가 git 저장소가 아닙니다. 수동 확인이 필요합니다."
    fi
else
    echo "📥 Flutter SDK (stable) 클론 중..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
fi

# 3. 환경 변수 임시 설정
export PATH="$FLUTTER_ROOT/bin:$PATH"

# 4. 초기화 및 프리캐싱
echo "⚙️  Flutter 바이너리 다운로드 및 초기화..."
flutter precache

# 5. 상태 확인
echo "🏥 Flutter Doctor 실행..."
# Android 라이선스는 dev.android 모듈에서 이미 처리했으므로 대게 통과함.
# 에러가 나더라도 스크립트를 중단하지 않고 경고만 보여줌.
flutter doctor || echo "⚠️  Flutter Doctor에서 일부 경고가 발견되었습니다. 위 내용을 확인하세요."

echo "🎉 Flutter 설치 완료."
