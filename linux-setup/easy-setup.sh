#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------
# Linux Setup Assistant v3.0 - fzf 기반 TUI
# ---------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# 설정 경로
CONFIG_DIR="$SCRIPT_DIR/config"
MODULES_DIR="$SCRIPT_DIR/modules"
PRESETS_DIR="$SCRIPT_DIR/presets"
CATEGORIES_FILE="$CONFIG_DIR/categories.json"
PREVIEW_SCRIPT="$SCRIPT_DIR/lib/preview.sh"

# 전역 변수 초기화
UI_TITLE="Linux Setup Assistant"
UI_VERSION="3.0"
SELECTED_FILE=""

# 도움말 (먼저 정의)
show_help() {
    cat << 'EOF'
🐧 Linux Setup Assistant v3.0

사용법:
  ./easy-setup.sh                    # 대화형 모드
  ./easy-setup.sh --preset base      # 프리셋으로 시작
  ./easy-setup.sh --preset base --execute  # 프리셋 바로 실행
  ./easy-setup.sh --preset base --dry-run  # 시뮬레이션

옵션:
  --preset <name>     프리셋 파일 또는 이름
  --execute, --run    바로 설치 실행
  --dry-run           시뮬레이션 모드
  --vscode-extras     VSCode 확장 프로필 (예: java,python)
  --debug             디버그 모드
  --help, -h          도움말

키 조작:
  Tab          모듈 선택/해제
  Enter        확정
  Ctrl+A       전체 선택
  Ctrl+D       전체 해제
  /            검색
  Esc          종료
EOF
}

# CLI 인자
PRESET_ARG=""
ACTION_MODE=""
VSCODE_EXTRAS=""
DEBUG_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset) PRESET_ARG="${2:-}"; shift 2 ;;
        --dry-run) ACTION_MODE="dry-run"; shift ;;
        --execute|--run) ACTION_MODE="execute"; shift ;;
        --debug) DEBUG_MODE=true; export DEBUG_SETUP=1; shift ;;
        --vscode-extras) VSCODE_EXTRAS="${2:-}"; shift 2 ;;
        --help|-h) show_help; exit 0 ;;
        *) PRESET_ARG="$1"; shift ;;
    esac
done

# 라이브러리 로드
source "$SCRIPT_DIR/lib/core.sh"
source "$SCRIPT_DIR/lib/fzf-ui.sh"

# Error trap
trap 'log_error "Error at line $LINENO: $BASH_COMMAND"' ERR

# Root check
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "[ERROR] Do not run as root/sudo."
    exit 1
fi

# 데이터 구조
declare -A MODULES
declare -A MODULE_NAMES
declare -A MODULE_DEPS

# 모듈 로드
load_modules() {
    MODULES=()
    MODULE_NAMES=()
    MODULE_DEPS=()
    
    while IFS= read -r meta_file; do
        [[ -z "$meta_file" ]] && continue
        local mid mname mdeps
        mid=$(jq -r '.id' "$meta_file")
        mname=$(jq -r '.name' "$meta_file")
        mdeps=$(jq -r '.requires[]? // empty' "$meta_file" | tr '\n' ' ')
        
        MODULES["$mid"]=$(dirname "$meta_file")
        MODULE_NAMES["$mid"]="$mname"
        MODULE_DEPS["$mid"]="$mdeps"
    done < <(find "$MODULES_DIR" -name "meta.json" 2>/dev/null)
}

# 의존성 해결 (위상 정렬) - bash 4.2 호환
INSTALL_LIST=()
declare -A DEP_VISITED
declare -A DEP_IN_PROGRESS

resolve_one_dep() {
    local id="$1"
    local base_id="${id%%:*}"
    
    [[ -n "${DEP_VISITED[$id]:-}" ]] && return 0
    [[ -n "${DEP_IN_PROGRESS[$id]:-}" ]] && { log_warn "Circular dependency: $id"; return 0; }
    
    DEP_IN_PROGRESS[$id]=1
    
    # 의존성 먼저 처리
    local deps="${MODULE_DEPS[$base_id]:-}"
    for dep in $deps; do
        resolve_one_dep "$dep"
    done
    
    unset 'DEP_IN_PROGRESS[$id]'
    DEP_VISITED[$id]=1
    INSTALL_LIST+=("$id")
}

resolve_dependencies() {
    INSTALL_LIST=()
    DEP_VISITED=()
    DEP_IN_PROGRESS=()
    
    # 선택된 모든 항목에 대해 의존성 해결
    while IFS= read -r item; do
        [[ -n "$item" ]] && resolve_one_dep "$item"
    done < "$SELECTED_FILE"
}

# 프리셋 로드
load_preset() {
    local preset_file="$1"
    [[ ! -f "$preset_file" ]] && return 1
    
    # 선택 파일 초기화
    > "$SELECTED_FILE"
    
    # 프리셋의 모듈들을 선택 목록에 추가
    local modules
    modules=$(jq -c '.modules[]' "$preset_file" 2>/dev/null) || return 1
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        local pid pver psel pkey
        pid=$(jq -r '.id' <<< "$entry")
        pver=$(jq -r '.params.version // empty' <<< "$entry")
        psel=$(jq -r 'if .params.selected == false then "false" else "true" end' <<< "$entry")
        
        [[ "$psel" == "false" ]] && continue
        
        pkey="${pid}${pver:+:$pver}"
        add_selected "$pkey"
    done <<< "$modules"
    
    return 0
}

# 설치 실행
run_installation() {
    local dry_run="$1"
    
    # 의존성 해결
    resolve_dependencies
    
    if [[ ${#INSTALL_LIST[@]} -eq 0 ]]; then
        log_warn "설치할 모듈이 없습니다."
        return 1
    fi
    
    echo ""
    log_info "━━━ 설치 순서 (의존성 해결됨) ━━━"
    for item in "${INSTALL_LIST[@]}"; do
        echo "  → $item"
    done
    echo ""
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "🔍 시뮬레이션 모드 - 실제 설치 없음"
        return 0
    fi
    
    # sudo 캐시
    sudo -v
    
    LOG_FILE="/tmp/easy-setup-$(date +%Y%m%d_%H%M%S).log"
    touch "$LOG_FILE"
    log_info "로그 파일: $LOG_FILE"
    echo ""
    
    local failed=()
    
    for item in "${INSTALL_LIST[@]}"; do
        local mid="${item%%:*}"
        local variant="${item#*:}"
        [[ "$mid" == "$variant" ]] && variant=""
        
        local mpath="${MODULES[$mid]:-}"
        [[ -z "$mpath" ]] && { log_warn "모듈 없음: $mid"; continue; }
        
        local script="$mpath/install.sh"
        local name="${MODULE_NAMES[$mid]:-$mid}"
        
        echo ""
        log_info ">>> [$name${variant:+ $variant}] 설치 중..."
        
        if [[ -x "$script" ]]; then
            set +e
            local args=()
            [[ -n "$variant" ]] && args+=("$variant")
            
            # VSCode 확장 처리
            if [[ "$mid" == "gui.vscode" && -n "$VSCODE_EXTRAS" ]]; then
                IFS=',' read -ra extras <<< "$VSCODE_EXTRAS"
                args+=("${extras[@]}")
            fi
            
            if [[ "${DEBUG_SETUP:-}" == "1" ]]; then
                bash -x "$script" "${args[@]}" 2>&1 | tee -a "$LOG_FILE"
            else
                "$script" "${args[@]}" 2>&1 | tee -a "$LOG_FILE"
            fi
            
            local rc=${PIPESTATUS[0]}
            set -e
            
            if [[ $rc -ne 0 ]]; then
                log_error "실패: $name ($rc)"
                failed+=("$item")
            else
                log_success "완료: $name"
                
                # 테스트 실행
                if [[ -f "$mpath/test.sh" ]]; then
                    run_module_test "$mpath" 2>&1 | tee -a "$LOG_FILE" || true
                fi
            fi
        else
            log_warn "실행 파일 없음: $script"
        fi
    done
    
    echo ""
    if [[ ${#failed[@]} -eq 0 ]]; then
        log_success "━━━ 모든 설치 완료! ━━━"
    else
        log_error "━━━ 일부 실패: ${failed[*]} ━━━"
        return 1
    fi
}

# VSCode 확장 선택
select_vscode_extensions() {
    local ext_dir="$MODULES_DIR/gui/vscode/extensions"
    [[ ! -d "$ext_dir" ]] && return
    
    local ext_list="✓ base (필수)|base\n"
    while IFS= read -r ef; do
        local p
        p=$(basename "$ef" .json)
        [[ "$p" != "base" ]] && ext_list+="  $p|$p\n"
    done < <(find "$ext_dir" -name "*.json" 2>/dev/null | sort)
    
    local selected
    selected=$(echo -e "$ext_list" | fzf \
        --ansi \
        --multi \
        --reverse \
        --header "VSCode 확장 프로필 선택" \
        --delimiter '\|' \
        --with-nth 1 \
        2>/dev/null) || true
    
    VSCODE_EXTRAS=$(echo "$selected" | awk -F'|' '{print $2}' | tr '\n' ',' | sed 's/,$//')
}

# 메인 시작 메뉴
show_main_menu() {
    local choice
    choice=$(echo -e "📦 프리셋으로 설치\n🔧 직접 선택\n❌ 종료" | fzf \
        --ansi \
        --reverse \
        --header "$UI_TITLE v$UI_VERSION" \
        --header-first \
        --height 10 \
        2>/dev/null) || true
    
    case "$choice" in
        *"프리셋"*) echo "preset" ;;
        *"직접"*) echo "custom" ;;
        *) echo "exit" ;;
    esac
}

# ========== 메인 실행 ==========

# 초기화
load_ui_config || true
load_modules
ensure_utils
check_os
check_network

# fzf 확인
if ! command -v fzf &>/dev/null; then
    log_info "fzf 설치 중..."
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
        sudo apt-get update && sudo apt-get install -y fzf
    elif [[ "$OS_ID" == "fedora" ]]; then
        sudo dnf install -y fzf
    else
        log_error "fzf를 수동으로 설치해주세요"
        exit 1
    fi
fi

# 선택 파일 초기화
init_selected_file
chmod +x "$PREVIEW_SCRIPT" 2>/dev/null || true

# 모듈 캐시 초기화 (성능 향상)
init_module_cache "$MODULES_DIR"

# 프리셋 인자가 있으면 바로 로드
if [[ -n "$PRESET_ARG" ]]; then
    if [[ -f "$PRESET_ARG" ]]; then
        preset_file="$PRESET_ARG"
    else
        preset_file="$PRESETS_DIR/$PRESET_ARG.json"
    fi
    
    if load_preset "$preset_file"; then
        log_success "프리셋 로드: $(jq -r '.name' "$preset_file")"
        
        # --execute나 --dry-run이 있으면 바로 실행
        if [[ -n "$ACTION_MODE" ]]; then
            if [[ "$ACTION_MODE" == "execute" ]]; then
                run_installation false
            else
                run_installation true
            fi
            exit $?
        fi
    else
        log_error "프리셋 로드 실패: $PRESET_ARG"
        exit 1
    fi
fi

# 메인 루프
while true; do
    clear
    
    # 선택된 항목이 없으면 시작 메뉴
    if [[ ! -s "$SELECTED_FILE" ]]; then
        mode=$(show_main_menu)
        
        case "$mode" in
            "preset")
                preset_name=$(select_preset_fzf "$PRESETS_DIR") || true
                if [[ -n "$preset_name" ]]; then
                    load_preset "$PRESETS_DIR/$preset_name"
                    log_success "프리셋 로드됨"
                    sleep 0.5
                fi
                continue
                ;;
            "custom")
                # 직접 선택 모드로 진행
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    # fzf 선택 UI
    if ! run_fzf_selector "$MODULES_DIR" "$CATEGORIES_FILE" "$PREVIEW_SCRIPT"; then
        # Esc로 취소
        if [[ $(get_selected_count) -eq 0 ]]; then
            exit 0
        fi
        # 선택된 항목이 있으면 계속
    fi
    
    # 선택 확인
    count=$(get_selected_count)
    if [[ $count -eq 0 ]]; then
        continue
    fi
    
    # VSCode 선택 시 확장 선택
    if grep -q "gui.vscode" "$SELECTED_FILE" 2>/dev/null && [[ -z "$VSCODE_EXTRAS" ]]; then
        select_vscode_extensions
    fi
    
    # 설치 확인
    action=$(confirm_install_fzf)
    
    case "$action" in
        "execute")
            run_installation false
            read -rp "Enter를 눌러 종료..."
            exit 0
            ;;
        "dry-run")
            run_installation true
            read -rp "Enter를 눌러 계속..."
            ;;
        *)
            # 취소 - 다시 선택
            ;;
    esac
done
