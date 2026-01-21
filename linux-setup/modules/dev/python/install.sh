#!/bin/bash
set -e
VERSION="${1:-3.12}"

# 라이브러리 로드
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then source "$LIB_DIR/core.sh"; fi
fi

detect_os

echo "📦 시스템 패키지로 Python $VERSION 설치 시도..."

# 패키지명 결정
MAIN_PKG=""
if [[ "$VERSION" =~ ^3\.[0-9]+$ ]]; then
    MAIN_PKG="python$VERSION"
elif [[ "$VERSION" == "3" ]]; then
    MAIN_PKG="python3"
else
    # 3.12.1 등 세부 버전이 오면 3.12로 단축 시도
    SHORT_VER=$(echo "$VERSION" | cut -d. -f1,2)
    MAIN_PKG="python$SHORT_VER"
fi

INSTALLED_NATIVE=false

# 1. 시스템 패키지 설치
if install_packages "$MAIN_PKG"; then
    echo "✅ Python 기본 패키지($MAIN_PKG) 설치 성공"
    INSTALLED_NATIVE=true
    
    # 추가 패키지 설치 (venv, dev, pip)
    EXTRAS=()
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
        EXTRAS+=("$MAIN_PKG-venv" "$MAIN_PKG-dev" "python3-pip")
    elif [[ "$OS_ID" == "fedora" ]]; then
        EXTRAS+=("$MAIN_PKG-devel" "python3-pip")
    fi
    
    if [ ${#EXTRAS[@]} -gt 0 ]; then
        install_packages "${EXTRAS[@]}" || echo "⚠️  일부 Python 추가 패키지 설치 실패 (치명적이지 않음)"
    fi
else
    echo "⚠️  시스템 패키지($MAIN_PKG) 설치 실패 또는 찾을 수 없음."
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# 2. Fallback: Pyenv
echo "🔄 Pyenv를 통한 설치 시도 (Fallback)..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [ ! -d "$PYENV_ROOT" ]; then
    echo "Pyenv 설치 중..."
    if curl https://pyenv.run | bash; then
        echo "Pyenv 설치 완료"
    else
        echo "Pyenv 설치 실패"
        exit 1
    fi
fi

eval "$(pyenv init -)" 2>/dev/null || true

LATEST_VERSION=$(pyenv install --list 2>/dev/null | grep -E "^\s*${VERSION//./\.}\.[0-9]+$" | tail -1 | xargs)
if [ -z "$LATEST_VERSION" ]; then
    LATEST_VERSION="$VERSION"
fi

echo "Pyenv로 Python $LATEST_VERSION 설치 중..."
pyenv install "$LATEST_VERSION" --skip-existing
pyenv global "$LATEST_VERSION"