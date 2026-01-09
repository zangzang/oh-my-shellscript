#!/bin/bash
set -e
VERSION="${1:-}"
export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "SDKMAN이 설치되어 있지 않습니다: $SDKMAN_DIR"
    echo "먼저 dev.sdkman 모듈을 설치하세요."
    exit 1
fi

# SDKMAN 초기화 (ZSH_VERSION 등 미정의 변수 참조로 인한 set -u 오류 방지)
# shellcheck disable=SC1090
nounset_was_on=0
case "$-" in *u*) nounset_was_on=1 ;; esac
set +u
source "$SDKMAN_DIR/bin/sdkman-init.sh"
if (( nounset_was_on )); then set -u; fi

if ! type sdk >/dev/null 2>&1; then
    echo "SDKMAN 초기화에 실패했습니다 (sdk 명령을 찾을 수 없음)."
    exit 1
fi

if [[ -z "$VERSION" ]]; then
    VERSION="17" # Default to 17 if not specified
fi

pick_latest_temurin_for_major() {
    local major="$1"
    # sdk list java 출력에서 temurin 식별자(예: 21.0.5-tem)만 추출 후 버전 정렬
    sdk list java 2>/dev/null \
        | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+-tem' \
        | grep -E "^${major}\." \
        | sort -V \
        | tail -n 1
}

VERSION_STR=""

# VERSION이 이미 구체 버전 식별자면 그대로 사용(예: 21.0.5-tem)
if [[ "$VERSION" == *.* || "$VERSION" == *-* ]]; then
    VERSION_STR="$VERSION"
else
    # major만 받은 경우(21/17/8): 가능한 최신 temurin 후보 선택
    VERSION_STR="$(pick_latest_temurin_for_major "$VERSION")"
    if [[ -z "$VERSION_STR" ]]; then
        # temurin 후보를 못 찾으면 major alias로 설치를 시도(설치 후 디렉토리로 성공 판정)
        VERSION_STR="$VERSION"
    fi
fi

JAVA_DIR="$SDKMAN_DIR/candidates/java/$VERSION_STR"

set +u
if [[ -d "$JAVA_DIR" ]]; then
    echo "✅ Java $VERSION ($VERSION_STR) 이미 설치됨"
    sdk default java "$VERSION_STR" >/dev/null 2>&1 || echo "  (default 설정 건너뜀)"
else
    echo "Java $VERSION ($VERSION_STR) 설치 중..."
    # pipefail + yes| 파이프 조합은 SIGPIPE로 성공을 실패로 오판할 수 있어 here-string 사용
    set +e
    sdk install java "$VERSION_STR" <<<"y"
    install_rc=$?
    set -e
    # 0 또는 1 (이미 설치됨)은 성공으로 처리
    if [[ $install_rc -ne 0 && $install_rc -ne 1 ]]; then
        echo "⚠️  Java 설치 명령 실패 (exit=$install_rc), 설치 여부를 확인합니다..."
    fi

    # major alias로 설치한 경우, 실제 설치된 디렉토리명이 다를 수 있어 재탐색
    if [[ ! -d "$JAVA_DIR" && "$VERSION_STR" =~ ^[0-9]+$ ]]; then
        resolved_dir=$(ls -1 "$SDKMAN_DIR/candidates/java" 2>/dev/null | grep -E "^${VERSION_STR}\\.[0-9]+\\.[0-9]+-" | sort -V | tail -n 1 || true)
        if [[ -n "$resolved_dir" ]]; then
            JAVA_DIR="$SDKMAN_DIR/candidates/java/$resolved_dir"
            VERSION_STR="$resolved_dir"
        fi
    fi

    if [[ -d "$JAVA_DIR" ]]; then
        echo "✅ Java 설치 완료: $VERSION_STR"
        sdk default java "$VERSION_STR" >/dev/null 2>&1 || echo "  (default 설정 건너뜀)"
        
        # 시스템 전역 경로 심볼릭 링크 생성 (편의성)
        if [[ -x "$JAVA_DIR/bin/java" ]]; then
            echo "전역 심볼릭 링크 생성 중..."
            sudo ln -sf "$JAVA_DIR/bin/java" /usr/local/bin/java
            sudo ln -sf "$JAVA_DIR/bin/javac" /usr/local/bin/javac
        fi
    else
        echo "❌ Java 설치 실패: $VERSION_STR (플랫폼/배포판에서 제공되지 않을 수 있음)"
        echo "   확인: sdk list java"
        exit 1
    fi
fi
if (( nounset_was_on )); then
    set -u
fi
