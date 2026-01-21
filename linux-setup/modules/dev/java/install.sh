#!/bin/bash
set -e
VERSION="${1:-17}"

# 라이브러리 로드 (필요시)
if ! command -v install_packages &>/dev/null; then
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # .../modules/dev/java -> ../../../lib
    LIB_DIR="$(cd "$CURRENT_DIR/../../../lib" && pwd)"
    if [[ -f "$LIB_DIR/core.sh" ]]; then
        source "$LIB_DIR/core.sh"
    fi
fi

# OS 감지 확인
if [ -z "${OS_ID:-}" ]; then
    detect_os
fi

# 패키지 매핑 함수
get_java_package() {
    local ver="$1"
    local os="${OS_ID:-unknown}"
    
    if [[ "$os" == "fedora" ]]; then
        case "$ver" in
            8) echo "java-1.8.0-openjdk-devel" ;;
            11) echo "java-11-openjdk-devel" ;;
            17) echo "java-17-openjdk-devel" ;;
            21) echo "java-21-openjdk-devel" ;;
            22) echo "java-22-openjdk-devel" ;;
            25) echo "java-latest-openjdk-devel" ;; # Fedora might not have 25 yet, using latest
            *) echo "java-latest-openjdk-devel" ;;
        esac
    elif [[ "$os" == "ubuntu" || "$os" == "debian" || "$os" == "pop" || "$os" == "linuxmint" ]]; then
        case "$ver" in
            8) echo "openjdk-8-jdk" ;;
            11) echo "openjdk-11-jdk" ;;
            17) echo "openjdk-17-jdk" ;;
            21) echo "openjdk-21-jdk" ;;
            25) echo "openjdk-25-jdk" ;; # Might not exist
            *) echo "default-jdk" ;;
        esac
    else
        echo ""
    fi
}

PKG_NAME=$(get_java_package "$VERSION")

# 1. 시스템 패키지 매니저 시도
INSTALLED_NATIVE=false
if [[ -n "$PKG_NAME" ]]; then
    echo "📦 시스템 패키지로 Java $VERSION 설치 시도 ($PKG_NAME)..."
    # install_packages는 에러 시 1 반환 가정
    if install_packages "$PKG_NAME"; then
        echo "✅ Java 설치 완료 (System Package)"
        INSTALLED_NATIVE=true
    else
        echo "⚠️  시스템 패키지 설치 실패. Fallback 모드로 전환합니다."
    fi
fi

if [[ "$INSTALLED_NATIVE" == "true" ]]; then
    exit 0
fi

# 2. Fallback: SDKMAN
echo "🔄 SDKMAN을 통한 설치 시도..."

export SDKMAN_DIR="$HOME/.sdkman"
export sdkman_auto_answer=true

# SDKMAN 없으면 설치
if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "SDKMAN 다운로드 및 설치 중..."
    curl -s "https://get.sdkman.io" | bash
fi

# SDKMAN 초기화
set +u
source "$SDKMAN_DIR/bin/sdkman-init.sh"
set -u

if ! type sdk >/dev/null 2>&1; then
    echo "❌ SDKMAN 초기화 실패"
    exit 1
fi

# 기존 로직 재사용 (버전 매핑 등)
# SDKMAN용 버전 문자열 계산
sdk_version="$VERSION"
if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    # 간단히 Temurin 최신 버전 선택 로직 (생략하거나 단순화)
    # 여기서는 SDKMAN의 기본 식별자 사용 시도
    sdk_version="$VERSION-tem" 
    # 하지만 정확한 식별자를 모르면 쿼리가 필요함.
    # 이전 스크립트의 로직을 일부 가져옴
    echo "SDKMAN에서 Java $VERSION 검색 중..."
    
    # sdk list java 결과에서 버전 파싱은 복잡하므로
    # 사용자가 정확한 버전을 입력하지 않은 경우 
    # 단순히 'java x.y.z-tem' 패턴 매칭 시도
    
    CANDIDATE=$(sdk list java | grep -Eo "${VERSION}\.[0-9]+\.[0-9]+-tem" | head -1 || true)
    if [[ -n "$CANDIDATE" ]]; then
        sdk_version="$CANDIDATE"
    fi
fi

echo "SDKMAN으로 Java 설치: $sdk_version"
sdk install java "$sdk_version" <<<"y"