#!/bin/bash
set -e
VERSION="$1"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if [[ -z "$VERSION" ]]; then
    VERSION="3.12"
fi

# Pyenv 설치 확인 및 설치
if [ ! -d "$PYENV_ROOT" ]; then
    echo "Pyenv 설치 중..."
    if curl https://pyenv.run | bash; then
        echo "Pyenv 설치 완료"
    else
        echo "Pyenv 설치 실패"
        exit 1
    fi
fi

# pyenv 초기화 (현재 세션용)
eval "$(pyenv init -)" 2>/dev/null || true

# 정확한 버전 찾기 (예: 3.12 -> 3.12.8)
LATEST_VERSION=$(pyenv install --list 2>/dev/null | grep -E "^\s*${VERSION//./\\.}\.[0-9]+$" | tail -1 | xargs)

if [ -z "$LATEST_VERSION" ]; then
    echo "버전을 찾을 수 없어 기본값($VERSION)으로 시도합니다."
    LATEST_VERSION="$VERSION"
fi

echo "Python $LATEST_VERSION 설치 중..."
pyenv install "$LATEST_VERSION" --skip-existing
pyenv global "$LATEST_VERSION"

echo "Python $LATEST_VERSION 설정 완료."
