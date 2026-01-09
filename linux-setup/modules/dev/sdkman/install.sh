#!/bin/bash
set -e

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [ -d "$SDKMAN_DIR" ]; then
    echo "SDKMAN 이미 설치됨"
    # SDKMAN 초기화하여 Maven, Gradle 설치 확인
    if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        nounset_was_on=0
        case "$-" in *u*) nounset_was_on=1 ;; esac
        set +u
        # shellcheck disable=SC1090
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        if (( nounset_was_on )); then set -u; fi
    fi
else
    echo "SDKMAN 설치 중..."
    if curl -s "https://get.sdkman.io?rcupdate=false" | bash; then
        echo "SDKMAN 설치 완료"
    else
        echo "SDKMAN 설치 실패"
        exit 1
    fi
    
    # SDKMAN 초기화
    if [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]; then
        nounset_was_on=0
        case "$-" in *u*) nounset_was_on=1 ;; esac
        set +u
        # shellcheck disable=SC1090
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        if (( nounset_was_on )); then set -u; fi
    fi
fi

# Maven 설치 (sdk 명령도 set -u 문제 회피)
if ! command -v mvn &>/dev/null; then
    echo "Maven 설치 중..."
    nounset_was_on=0
    case "$-" in *u*) nounset_was_on=1 ;; esac
    set +u
    set +e
    sdk install maven <<<"y"
    install_rc=$?
    set -e
    if [[ $install_rc -eq 0 || $install_rc -eq 1 ]]; then
        echo "✅ Maven 설치 완료"
    else
        echo "⚠️  Maven 설치 명령 실패 (exit=$install_rc)"
    fi
    if (( nounset_was_on )); then set -u; fi
else
    echo "✅ Maven 이미 설치됨"
fi

# Gradle 설치
if ! command -v gradle &>/dev/null; then
    echo "Gradle 설치 중..."
    nounset_was_on=0
    case "$-" in *u*) nounset_was_on=1 ;; esac
    set +u
    set +e
    sdk install gradle <<<"y"
    install_rc=$?
    set -e
    if [[ $install_rc -eq 0 || $install_rc -eq 1 ]]; then
        echo "✅ Gradle 설치 완료"
    else
        echo "⚠️  Gradle 설치 명령 실패 (exit=$install_rc)"
    fi
    if (( nounset_was_on )); then set -u; fi
else
    echo "✅ Gradle 이미 설치됨"
fi

echo "SDKMAN, Maven, Gradle 설정 완료"
