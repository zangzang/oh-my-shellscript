#!/bin/bash
set -e
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

echo "Fcitx5 및 한글 설정 설치 중..."

if [ "$OS_ID" == "fedora" ]; then
    sudo dnf install -y fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-hangul
    if command -v imsettings-switch &>/dev/null; then
        imsettings-switch fcitx5
    fi
else
    sudo apt install -y fcitx5 fcitx5-config-qt fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-hangul kde-config-fcitx5
    if command -v im-config &>/dev/null; then
        im-config -n fcitx5
    fi
fi

echo "Fcitx5 설치 완료. 재로그인 후 적용됩니다."
