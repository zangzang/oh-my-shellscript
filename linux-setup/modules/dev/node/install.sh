#!/bin/bash
set -e
VERSION="${1:-lts}"

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

# 시스템 패키지 설치 시도
echo "📦 시스템 패키지로 Node.js 설치 시도..."

TRY_NATIVE=false
if [[ "$OS_ID" == "fedora" ]]; then
    # Fedora는 nodejs에 npm이 포함됨
    if install_packages "nodejs"; then
        TRY_NATIVE=true
    fi
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    # Ubuntu는 nodejs와 npm이 분리된 경우 많음
    # NodeSource 등을 사용하지 않고 순수 OS 제공 버전 사용 (요청사항 반영)
    if install_packages "nodejs" "npm"; then
        TRY_NATIVE=true
    fi
fi

if [[ "$TRY_NATIVE" == "true" ]]; then
    echo "✅ Node.js (System) 설치 완료"
    node -v
    npm -v
    exit 0
fi

echo "⚠️  시스템 패키지 설치 실패 또는 미지원 OS. Fallback(NVM) 시도..."

# Fallback: NVM
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "NVM 설치 중..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
    echo "❌ NVM 로드 실패"
    exit 1
fi

case "$VERSION" in
    lts) TARGET="--lts" ;;
    current|latest) TARGET="node" ;;
    *) TARGET="$VERSION" ;;
esac

echo "NVM으로 Node.js 설치: $TARGET"
nvm install "$TARGET"
nvm use "$TARGET"
nvm alias default "$TARGET"