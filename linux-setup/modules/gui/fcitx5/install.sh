#!/bin/bash
set -e
echo "Fcitx5 및 한글 설정 설치 중..."
sudo apt install -y fcitx5 fcitx5-config-qt fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-hangul kde-config-fcitx5

# 환경 변수 설정 (im-config 사용이 더 안전할 수 있음)
# 여기서는 패키지 설치에 집중하고, 전체 설정은 별도 설정 모듈이나 안내로 처리
im-config -n fcitx5

echo "Fcitx5 설치 완료. 재로그인 후 적용됩니다."
