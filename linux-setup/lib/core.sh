#!/bin/bash

# 라이브러리 로드 (상대 경로 처리)
# core.sh가 로드되는 시점에 SCRIPT_DIR이 정의되어 있다고 가정하거나, 현재 파일 위치 기준으로 로드
CURRENT_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_LIB_DIR/distro.sh"
source "$CURRENT_LIB_DIR/ui.sh"

# 필수 유틸리티 확인 및 설치 (jq, fzf, gum, awk)
ensure_utils() {
    local needed=()
    command -v jq >/dev/null || needed+=("jq")
    command -v fzf >/dev/null || needed+=("fzf")
    command -v gum >/dev/null || needed+=("gum")
    command -v awk >/dev/null || needed+=("gawk") # awk가 없으면 gawk 설치

    if [ ${#needed[@]} -gt 0 ]; then
        ui_log_info "필수 유틸리티 설치 중: ${needed[*]}"
        
        if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ] || [ "$OS_ID" == "pop" ] || [ "$OS_ID" == "linuxmint" ]; then
            sudo mkdir -p /etc/apt/keyrings
            if [ ! -f /etc/apt/keyrings/charm.gpg ]; then
                curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            fi
            if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
            fi
            sudo apt update && sudo apt install -y "${needed[@]}"

        elif [ "$OS_ID" == "fedora" ]; then
            if [ ! -f /etc/yum.repos.d/charm.repo ]; then
                echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
            fi
            sudo dnf install -y "${needed[@]}"
        
        else
            echo "자동 설치를 지원하지 않는 OS입니다: $OS_ID"
            echo "수동으로 다음 패키지를 설치해주세요: ${needed[*]}"
            exit 1
        fi
        
        # 설치 후 Gum 사용 가능 여부 갱신
        if command -v gum >/dev/null 2>&1; then
            HAS_GUM=true
        fi
    fi
}

check_network() {
    ui_log_info "네트워크 연결 확인 중..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        ui_log_error "⚠️  인터넷 연결이 필요합니다."
        exit 1
    fi
    ui_log_success "네트워크 연결 확인됨"
}

check_os() {
    detect_os # from distro.sh
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "fedora" && "$OS_ID" != "debian" ]]; then
        ui_log_warn "⚠️  이 스크립트는 Ubuntu/Debian 및 Fedora 기반 시스템에 최적화되어 있습니다."
        echo -e "   현재 시스템: ${OS_ID} ${OS_VERSION}"
        
        if ! ui_confirm "계속 진행하시겠습니까?"; then
            exit 0
        fi
    fi
}

# 모듈 테스트 실행
run_module_test() {
    local module_path="$1"
    local test_script="${module_path}/test.sh"
    
    if [ ! -f "$test_script" ]; then
        ui_log_warn "테스트 스크립트가 없습니다: $test_script"
        return 1
    fi
    
    ui_log_info "테스트 실행 중..."
    if bash "$test_script"; then
        ui_log_success "✅ 테스트 통과"
        return 0
    else
        ui_log_error "❌ 테스트 실패"
        return 1
    fi
}

# 구버전 호환성을 위한 래퍼 (필요 시)
log_info() { ui_log_info "$1"; }
log_success() { ui_log_success "$1"; }
log_warn() { ui_log_warn "$1"; }
log_error() { ui_log_error "$1"; }
