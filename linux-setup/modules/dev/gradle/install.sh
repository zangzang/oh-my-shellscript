#!/bin/bash
set -e

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "SDKMAN이 설치되어 있지 않습니다: $SDKMAN_DIR"
    echo "먼저 dev.sdkman 모듈을 설치하세요."
    exit 1
fi

# SDKMAN 초기화
nounset_was_on=0
if [[ "$-" =~ u ]]; then
    nounset_was_on=1
    set +u
fi

# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"

if [[ $nounset_was_on -eq 1 ]]; then
    set -u
fi

echo "Gradle 설치 중..."
sdk install gradle

echo "✅ Gradle 설치 완료"
