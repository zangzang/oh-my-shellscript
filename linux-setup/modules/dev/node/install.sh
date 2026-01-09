#!/bin/bash
set -e

VERSION="${1:-lts}"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# NVM이 로드되었는지 확인
if ! command -v nvm &>/dev/null; then
    echo "❌ NVM이 설치되어 있지 않습니다. dev.nvm 모듈을 먼저 설치하세요."
    exit 1
fi

# 버전 형식 변환
case "$VERSION" in
    lts)
        TARGET="lts/*"
        ALIAS="lts"
        ;;
    current|latest)
        TARGET="node"
        ALIAS="current"
        ;;
    *)
        TARGET="$VERSION"
        ALIAS="$VERSION"
        ;;
esac

echo "Node.js $VERSION 설치 중... (target: $TARGET)"

# 이미 설치되어 있는지 확인
if nvm ls "$TARGET" &>/dev/null; then
    echo "✅ Node.js $VERSION 이미 설치됨"
    nvm use "$TARGET"
    nvm alias default "$TARGET"
    echo "현재 버전: $(node --version)"
    exit 0
fi

# 설치
if nvm install "$TARGET"; then
    nvm use "$TARGET"
    nvm alias default "$TARGET"
    echo "✅ Node.js 설치 완료: $(node --version)"
    echo "   npm 버전: $(npm --version)"
else
    echo "❌ Node.js 설치 실패"
    exit 1
fi

