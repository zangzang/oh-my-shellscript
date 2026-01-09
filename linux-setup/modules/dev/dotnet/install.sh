#!/bin/bash
set -e
VERSION="$1"

if [[ -z "$VERSION" ]]; then
    VERSION="9"
fi

# 버전 정규화: "8" -> "8.0", "9" -> "9.0", etc
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    VERSION="${VERSION}.0"
fi

echo ".NET SDK $VERSION 설치 중..."

# .NET 설치 (다른 모듈들과 일관되게 curl | bash 방식 사용)
if ! curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel "$VERSION" --install-dir "$HOME/.dotnet" --no-path; then
    echo ".NET 설치 실패"
    exit 1
fi

# 경로 설정은 사용자 쉘 환결 설정에 맡기거나, core.sh 등 공통에서 처리 권장하지만
# 여기서는 필요한 경우 추가하도록 안내만 하거나, idempotent 하게 추가 가능.
if ! grep -q '\.dotnet' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.zshrc"
fi
if ! grep -q '\.dotnet' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$HOME/.bashrc"
fi

echo ".NET SDK $VERSION 설치 완료"
