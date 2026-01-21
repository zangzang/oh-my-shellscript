#!/bin/bash
set -e

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "📱 Android 개발 환경 및 에뮬레이터 설정 중..."

# 1. 가상화 및 필수 의존성 설치 (KVM 등)
echo "📦 가상화 관련 시스템 패키지 설치..."
KVM_PKGS=()
if [[ "$OS_ID" == "fedora" ]]; then
    KVM_PKGS=("qemu-kvm" "bridge-utils" "libvirt" "virt-install" "unzip")
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    KVM_PKGS=("qemu-kvm" "libvirt-daemon-system" "libvirt-clients" "bridge-utils" "unzip" "libc6" "libstdc++6" "libbz2-1.0" "libncurses5")
fi

install_packages "${KVM_PKGS[@]}"

# 현재 사용자를 kvm/libvirt 그룹에 추가
if getent group kvm >/dev/null; then
    sudo usermod -aG kvm "$USER" || true
fi
if getent group libvirt >/dev/null; then
    sudo usermod -aG libvirt "$USER" || true
fi

# 2. Android SDK 디렉토리 설정
export ANDROID_HOME="$HOME/Android/Sdk"
CMDLINE_TOOLS_ROOT="$ANDROID_HOME/cmdline-tools"
mkdir -p "$CMDLINE_TOOLS_ROOT"

# 3. Command Line Tools 다운로드 (이미 설치되어 있지 않다면)
if [[ ! -d "$CMDLINE_TOOLS_ROOT/latest" ]]; then
    echo "📥 Android Command Line Tools 다운로드 중..."
    # 2024년 말 기준 최신 버전 (commandlinetools-linux-11076708_latest.zip)
    CMDLINE_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    TEMP_ZIP="/tmp/cmdline-tools.zip"
    
    curl -o "$TEMP_ZIP" "$CMDLINE_URL"
    unzip -q "$TEMP_ZIP" -d "$CMDLINE_TOOLS_ROOT"
    
    # 디렉토리 구조 재배치 (sdkmanager는 cmdline-tools/latest/bin/sdkmanager 위치를 기대함)
    mv "$CMDLINE_TOOLS_ROOT/cmdline-tools" "$CMDLINE_TOOLS_ROOT/latest"
    rm "$TEMP_ZIP"
    echo "✅ Command Line Tools 설치 완료"
else
    echo "✅ Command Line Tools 이미 존재함"
fi

# 환경 변수 임시 설정 (스크립트 내 실행용)
export PATH="$CMDLINE_TOOLS_ROOT/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# Java 확인 (dev.java 의존성이 있지만 환경변수가 없을 수 있음)
if ! command -v java &>/dev/null; then
    # SDKMAN 로드 시도
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

if ! command -v java &>/dev/null; then
    echo "❌ Java를 찾을 수 없습니다. dev.java 모듈이 설치되었는지 확인하세요."
    exit 1
fi

# 4. 라이선스 수락
echo "📜 Android SDK 라이선스 수락 중..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true

# 5. 필수 SDK 패키지 및 시스템 이미지 설치
# API Level 35 (Android 15) 기준
target_api="35"
build_tools_ver="35.0.0"
sys_img="system-images;android-${target_api};google_apis;x86_64"

echo "📥 SDK 패키지 및 에뮬레이터 이미지 다운로드 (시간이 걸릴 수 있습니다)..."
echo "   대상: platform-tools, platforms;android-${target_api}, build-tools;${build_tools_ver}, emulator, $sys_img"


sdkmanager "platform-tools" \
           "platforms;android-${target_api}" \
           "build-tools;${build_tools_ver}" \
           "emulator" \
           "$sys_img"

# 6. AVD(에뮬레이터) 생성
AVD_NAME="pixel_default"
if ! avdmanager list avd | grep -q "$AVD_NAME"; then
    echo "📱 기본 AVD($AVD_NAME) 생성 중..."
    # 'no'는 커스텀 하드웨어 프로필 설정 질문에 대한 답변
    echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$sys_img" --device "pixel" --force
    echo "✅ AVD 생성 완료: $AVD_NAME"
else
    echo "✅ AVD가 이미 존재합니다: $AVD_NAME"
fi

echo "🎉 Android 개발 환경 설정 완료."
echo "   KVM 그룹 적용을 위해 재로그인이 필요할 수 있습니다."
