#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[OK] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# 필수 유틸리티 확인 및 설치 (jq, gum)
ensure_utils() {
    local needed=()
    command -v jq >/dev/null || needed+=("jq")
    command -v gum >/dev/null || needed+=("gum")

    if [ ${#needed[@]} -gt 0 ]; then
        log_info "필수 유틸리티 설치 중: ${needed[*]}"
        sudo mkdir -p /etc/apt/keyrings
        if [ ! -f /etc/apt/keyrings/charm.gpg ]; then
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        fi
        
        # sources.list.d/charm.list 파일이 없거나 내용이 다르면 생성
        if [ ! -f /etc/apt/sources.list.d/charm.list ]; then
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        fi

        sudo apt update && sudo apt install -y "${needed[@]}"
    fi
}

check_network() {
    log_info "네트워크 연결 확인 중..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        log_error "⚠️  인터넷 연결이 필요합니다."
        exit 1
    fi
    log_success "네트워크 연결 확인됨"
}

check_os() {
    if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
        log_warn "⚠️  이 스크립트는 Ubuntu 기반 시스템에 최적화되어 있습니다."
        echo -e "${YELLOW}   현재 시스템: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)${NC}"
        # gum이 설치된 이후에 호출될 것이므로 gum confirm 사용 가능, 없으면 read
        if command -v gum >/dev/null; then
            if ! gum confirm "계속 진행하시겠습니까?"; then
                exit 0
            fi
        else
            read -p "계속 진행하시겠습니까? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    fi
}

# 모듈 테스트 실행
run_module_test() {
    local module_path="$1"
    local test_script="${module_path}/test.sh"
    
    if [ ! -f "$test_script" ]; then
        log_warn "테스트 스크립트가 없습니다: $test_script"
        return 1
    fi
    
    log_info "테스트 실행 중..."
    if bash "$test_script"; then
        log_success "✅ 테스트 통과"
        return 0
    else
        log_error "❌ 테스트 실패"
        return 1
    fi
}
