#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/core.sh"

# 에러 트랩 설정
trap 'log_error "스크립트 실행 중 오류 발생 (라인: $LINENO, 명령: $BASH_COMMAND)"' ERR

# 이 스크립트는 사용자 환경(HOME, SDKMAN, NVM 등)을 설정하므로 전체를 sudo로 실행하면 깨질 수 있습니다.
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    echo "[ERROR] easy-setup.sh는 sudo로 실행하지 마세요. (예: ./easy-setup.sh ...)"
    echo "        필요한 권한 상승은 각 모듈 내부에서 sudo로 처리합니다."
    exit 1
fi

script_uses_sudo() {
    local script_path="$1"
    [[ -f "$script_path" ]] || return 1
    # 대략적인 휴리스틱: sudo 명령 호출 여부
    grep -Eq '(^|[;&|[:space:]])sudo[[:space:]]' "$script_path"
}

usage() {
    cat <<'EOF'
Usage:
  ./easy-setup.sh                 # TUI (터미널에서만)
  ./easy-setup.sh <preset>        # TUI로 프리셋 로드 후 진행
  ./easy-setup.sh --preset <name> # 프리셋 지정

Non-interactive (셀/파이프/CI):
  ./easy-setup.sh --preset java-dev --dry-run
  ./easy-setup.sh --preset java-dev --execute
  ./easy-setup.sh --preset java-dev --vscode-extras dotnet,node --execute

Options:
  --dry-run              실제 설치 없이 시뮬레이션
  --execute              실제 설치 수행 (비대화형에서도 가능)
  --vscode-extras <grps> VSCode 확장 추가 그룹 (base는 자동) (예: dotnet,node)
                         가능한 그룹: java, dotnet, node, python, rust, optional
  --list-presets         프리셋 목록 출력
  --validate             프리셋/모듈 JSON 검증
  -h, --help             도움말
EOF
}

IS_TTY=false
if [[ -t 0 && -t 1 ]]; then
    IS_TTY=true
fi

PRESET_ARG=""
ACTION_MODE=""   # dry-run | execute
LIST_PRESETS=false
VALIDATE_ONLY=false
VSCODE_EXTRAS=""  # 추가할 VSCode 확장 그룹

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            PRESET_ARG="${2:-}"
            shift 2
            ;;
        --dry-run)
            ACTION_MODE="dry-run"
            shift
            ;;
        --execute|--run)
            ACTION_MODE="execute"
            shift
            ;;
        --vscode-extras)
            VSCODE_EXTRAS="${2:-}"
            shift 2
            ;;
        --list-presets)
            LIST_PRESETS=true
            shift
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$PRESET_ARG" ]]; then
                PRESET_ARG="$1"
                shift
            else
                log_error "알 수 없는 인자: $1"
                usage
                exit 1
            fi
            ;;
    esac
done

# 실행 권한 자동 수정 (압축 해제 후 권한 손실 대응)
fix_permissions() {
    local fixed=0
    while IFS= read -r install_script; do
        if [ ! -x "$install_script" ]; then
            chmod +x "$install_script" 2>/dev/null && fixed=$((fixed + 1)) || true
        fi
    done < <(find "$SCRIPT_DIR/modules" -name "install.sh" 2>/dev/null)
    
    if [ ${fixed} -gt 0 ]; then
        log_info "실행 권한 수정됨: ${fixed}개 파일"
    fi
}

fix_permissions

# 유틸리티 및 기본 환경 확인
ensure_utils
check_os
check_network

if [[ "$LIST_PRESETS" == "true" ]]; then
    find "$SCRIPT_DIR/presets" -maxdepth 1 -name "*.json" -printf '%f\n' | sort
    exit 0
fi

if [[ "$VALIDATE_ONLY" == "true" ]]; then
    if [[ -x "$SCRIPT_DIR/lib/validate.sh" ]]; then
        "$SCRIPT_DIR/lib/validate.sh"
        exit $?
    fi
    log_error "검증 스크립트를 찾을 수 없습니다: $SCRIPT_DIR/lib/validate.sh"
    exit 1
fi

# ------------------------------
# 1. 모듈 로드 및 유틸리티 함수
# ------------------------------
declare -A MODULES
declare -A MODULE_NAMES
declare -A MODULE_CATEGORIES
declare -A INSTALLED
declare -A RESOLVED_ORDER

load_modules() {
    # 기존 데이터 초기화
    MODULES=()
    MODULE_NAMES=()
    MODULE_CATEGORIES=()
    
    log_info "모듈 로드 중..."
    while IFS= read -r meta_file; do
        local id=$(jq -r '.id' "$meta_file")
        local name=$(jq -r '.name' "$meta_file")
        local cat=$(jq -r '.category // "other"' "$meta_file")
        
        MODULES["$id"]=$(dirname "$meta_file")
        MODULE_NAMES["$id"]="$name"
        MODULE_CATEGORIES["$id"]="$cat"
    done < <(find "$SCRIPT_DIR/modules" -name "meta.json")
}

resolve_dependencies() {
    local id_with_variant=$1
    local list_ref=$2
    
    local id="${id_with_variant%%:*}"
    local variant="${id_with_variant#*:}"
    if [[ "$id" == "$variant" ]]; then variant=""; fi

    # 방문 체크 (set -u 안전)
    [[ -n "${INSTALLED[$id_with_variant]:-}" ]] && return
    
    if [[ -z "${MODULES[$id]:-}" ]]; then
        log_error "모듈을 찾을 수 없습니다: $id"
        exit 1
    fi

    local meta_path="${MODULES[$id]}/meta.json"
    local deps=$(jq -r '.requires[]? // empty' "$meta_path")
    
    for dep in $deps; do
        resolve_dependencies "$dep" "$list_ref"
    done

    eval "$list_ref+=(\"$id_with_variant\")"
    INSTALLED[$id_with_variant]=1
}

# ------------------------------
# 2. 상태 머신 (State Machine)
# ------------------------------
load_modules

# Parse preset file into TARGET_MODULES and PRESET_DEFAULT_SELECTED map
parse_preset_file() {
    local preset_file="$1"
    TARGET_MODULES=""
    declare -gA PRESET_DEFAULT_SELECTED
    PRESET_DEFAULT_SELECTED=()

    while IFS= read -r entry; do
        id=$(jq -r '.id // empty' <<<"$entry")
        ver=$(jq -r '.params.version // empty' <<<"$entry")
        # Don't use // with boolean values - it treats false as null
        selected=$(jq -r 'if .params.selected == null then "true" else (.params.selected | tostring) end' <<<"$entry")

        if [[ -n "$ver" ]]; then
            key="$id:$ver"
        else
            key="$id"
        fi

        TARGET_MODULES+="$key\n"
        if [[ "$selected" == "false" ]]; then
            PRESET_DEFAULT_SELECTED["$key"]=0
        else
            PRESET_DEFAULT_SELECTED["$key"]=1
        fi
    done < <(jq -c '.modules[]' "$preset_file")

    TARGET_MODULES=$(echo -e "$TARGET_MODULES" | sed '/^$/d')
}

CURRENT_STATE="MODE_SELECT"
TARGET_MODULES=""
FINAL_LIST=()
USER_SELECTED_MODULES=()  # 사용자가 직접 선택한 모듈 (프리셋 또는 커스텀)
PRESET_FILE=""

# 프리셋 인자 처리 (원샷 실행 지원)
if [[ -n "$PRESET_ARG" ]]; then
    if [[ -f "$PRESET_ARG" ]]; then
        PRESET_FILE="$PRESET_ARG"
    elif [[ -f "$SCRIPT_DIR/presets/$PRESET_ARG.json" ]]; then
        PRESET_FILE="$SCRIPT_DIR/presets/$PRESET_ARG.json"
    elif [[ -f "$SCRIPT_DIR/presets/$PRESET_ARG" ]]; then
        PRESET_FILE="$SCRIPT_DIR/presets/$PRESET_ARG"
    fi

    if [[ -n "$PRESET_FILE" ]]; then
        parse_preset_file "$PRESET_FILE"
        CURRENT_STATE="RESOLVE_DEPS"
    else
        log_error "유효하지 않은 프리셋입니다: $PRESET_ARG"
        exit 1
    fi
fi

while true; do
    case "$CURRENT_STATE" in
        "MODE_SELECT")
            if [[ "$IS_TTY" != "true" ]]; then
                log_error "현재 실행 환경은 TUI를 지원하지 않습니다(tty 아님)."
                echo "- 터미널에서 실행: ./easy-setup.sh"
                echo "- 또는 프리셋 지정: ./easy-setup.sh --preset base --dry-run"
                exit 1
            fi
            clear
            gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" \
                "LINUX SETUP ASSISTANT" "Select mode"

            PRESET_CHOICES=""
            # all.json, base.json을 먼저, 나머지는 알파벳 순
            while IFS= read -r pfile; do
                if [[ -f "$pfile" ]]; then
                    pname=$(jq -r '.name // empty' "$pfile")
                    pdesc=$(jq -r '.description // empty' "$pfile")
                    base_fname=$(basename "$pfile" .json)
                    filename=$(basename "$pfile")
                    if [[ -z "$pname" ]]; then pname="$base_fname"; fi
                    PRESET_CHOICES+="📄 $pname ($pdesc) : $filename\n"
                fi
            done < <({ 
                find "$SCRIPT_DIR/presets" -name "all.json"
                find "$SCRIPT_DIR/presets" -name "base.json"
                find "$SCRIPT_DIR/presets" -name "*.json" ! -name "all.json" ! -name "base.json" | sort
            })
            
            PRESET_CHOICES+="👉 직접 선택 (Custom Selection) : custom\n"
            PRESET_CHOICES+="❌ 종료 (Exit) : exit"

            SELECTED_P_LINE=""
            EXIT_STATUS=0
            SELECTED_P_LINE=$(echo -e "$PRESET_CHOICES" | gum choose --header "시작 방법을 선택하세요" --height 12) || EXIT_STATUS=$?
            
            if [[ $EXIT_STATUS -ne 0 ]] || [[ -z "$SELECTED_P_LINE" ]]; then
                log_warn "종료합니다."
                exit 0
            fi

            SELECTED_VAL=$(echo "$SELECTED_P_LINE" | awk -F " : " '{print $2}' | xargs)

            if [[ "$SELECTED_VAL" == "exit" ]]; then
                log_info "종료합니다."
                exit 0
            elif [[ "$SELECTED_VAL" == "custom" ]]; then
                CURRENT_STATE="CUSTOM_SELECT"
            else
                PRESET_FILE="$SCRIPT_DIR/presets/$SELECTED_VAL"
                log_info "프리셋 로드: $PRESET_FILE"
                parse_preset_file "$PRESET_FILE"
                CURRENT_STATE="RESOLVE_DEPS"
            fi
            ;;

        "CUSTOM_SELECT")
            clear
            gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" \
                "LINUX SETUP ASSISTANT" "Manual Selection"
            
            CHOICES=""
            for id in "${!MODULES[@]}"; do 
                meta_path="${MODULES[$id]}/meta.json"
                name="${MODULE_NAMES[$id]}"
                category="${MODULE_CATEGORIES[$id]}"
                category_display="$(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"
                
                variants=$(jq -r '.variants[]? // empty' "$meta_path")
                
                if [[ -n "$variants" ]]; then
                    for v in $variants; do
                        CHOICES+="[${category_display}] $name ($v) : $id:$v\n"
                    done
                else
                    CHOICES+="[${category_display}] $name : $id\n"
                fi
            done
            
            # 정렬하여 표시
            SORTED_CHOICES=$(echo -e "$CHOICES" | sort)

            SELECTED=""
            EXIT_STATUS=0
            SELECTED=$(echo -e "$SORTED_CHOICES" | gum choose --no-limit --header "설치할 모듈을 선택하세요 (ESC: 뒤로가기)" --height 20) || EXIT_STATUS=$?

            if [[ $EXIT_STATUS -ne 0 ]]; then
                CURRENT_STATE="MODE_SELECT"
                continue
            fi
            
            if [[ -z "$SELECTED" ]]; then
                if gum confirm "선택된 항목이 없습니다. 뒤로 가시겠습니까?"; then
                    CURRENT_STATE="MODE_SELECT"
                else
                    continue
                fi
            else
                TARGET_MODULES=$(echo "$SELECTED" | awk -F " : " '{print $2}')
                CURRENT_STATE="RESOLVE_DEPS"
            fi
            ;;

        "RESOLVE_DEPS")
            FINAL_LIST=()
            INSTALLED=()
            USER_SELECTED_MODULES=()
            log_info "의존성 해결 중..."
            
            for mod in $TARGET_MODULES; do
                # Skip modules with selected:false in preset
                if [[ -n "$PRESET_FILE" ]] && declare -p PRESET_DEFAULT_SELECTED >/dev/null 2>&1; then
                    sel_value=${PRESET_DEFAULT_SELECTED["$mod"]:-1}
                    if [[ $sel_value -eq 0 ]]; then
                        continue
                    fi
                fi
                USER_SELECTED_MODULES+=("$mod")
                resolve_dependencies "$mod" FINAL_LIST
            done
            
            # VSCode 모듈이 선택되었고 TUI이면 확장 선택 화면 표시
            VSCODE_SELECTED=false
            for mod_entry in "${USER_SELECTED_MODULES[@]}"; do
                if [[ "$mod_entry" == "gui.vscode"* ]]; then
                    VSCODE_SELECTED=true
                    break
                fi
            done
            
            if [[ "$VSCODE_SELECTED" == "true" && "$IS_TTY" == "true" && -z "$VSCODE_EXTRAS" ]]; then
                CURRENT_STATE="VSCODE_PROFILE_SELECT"
            elif [[ -n "$ACTION_MODE" ]]; then
                # 실행 모드가 명시되면(자동화) TTY 여부와 관계 없이 바로 실행
                if [[ "$ACTION_MODE" == "execute" ]]; then
                    DRY_RUN=false
                    log_info "자동 실행: Execute 모드"
                else
                    DRY_RUN=true
                    log_info "자동 실행: Dry Run 모드"
                fi

                echo ""
                log_info "설치 대상(의존성 포함):"
                for mod_entry in "${FINAL_LIST[@]}"; do
                    echo "- $mod_entry"
                done
                CURRENT_STATE="INSTALL_RUN"
            elif [[ "$IS_TTY" == "true" ]]; then
                CURRENT_STATE="REVIEW_LIST"
            else
                # 비대화형 + 실행모드 미지정: 안전하게 안내 후 종료
                log_error "현재 실행 환경은 TUI를 지원하지 않습니다(tty 아님)."
                echo "- 프리셋 지정 + dry-run: ./easy-setup.sh --preset base --dry-run"
                echo "- 프리셋 지정 + execute: ./easy-setup.sh --preset base --execute"
                exit 1
            fi
            ;;

        "VSCODE_PROFILE_SELECT")
            # VSCode 확장 그룹 선택
            clear
            gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" \
                "VSCode EXTENSIONS" "Select development profiles"
            
            # 확장 그룹 디렉토리 확인
            EXT_DIR="$SCRIPT_DIR/modules/gui/vscode/extensions"
            if [[ ! -d "$EXT_DIR" ]]; then
                log_error "VSCode 확장 디렉토리를 찾을 수 없습니다: $EXT_DIR"
                CURRENT_STATE="REVIEW_LIST"
                continue
            fi
            
            # 가용한 확장 그룹 목록 (base 제외, 항상 포함됨)
            EXT_CHOICES="✓ Base (Required) : base\n"
            while IFS= read -r ext_file; do
                profile=$(basename "$ext_file" .json)
                if [[ "$profile" != "base" ]]; then
                    desc=$(jq -r '.description // ""' "$ext_file" 2>/dev/null || echo "")
                    EXT_CHOICES+="  $profile : $profile\n"
                fi
            done < <(find "$EXT_DIR" -name "*.json" | sort)
            
            EXT_CHOICES=$(echo -e "$EXT_CHOICES" | sed '/^$/d')
            
            SELECTED_PROFILES=""
            EXIT_STATUS=0
            SELECTED_PROFILES=$(echo -e "$EXT_CHOICES" | gum choose --no-limit --header "설치할 VSCode 확장 그룹을 선택하세요 (base는 항상 포함)" --height 10) || EXIT_STATUS=$?
            
            if [[ $EXIT_STATUS -ne 0 ]]; then
                CURRENT_STATE="RESOLVE_DEPS"
                continue
            fi
            
            # 선택된 프로필을 comma 구분자로 변환
            if [[ -n "$SELECTED_PROFILES" ]]; then
                VSCODE_EXTRAS=$(echo "$SELECTED_PROFILES" | awk -F " : " '{print $2}' | tr '\n' ',' | sed 's/,$//')
            fi
            
            CURRENT_STATE="REVIEW_LIST"
            ;;

        "REVIEW_LIST")
            CONFIRM_ITEMS=""
            SELECTED_ITEMS=""
            # 사용자가 직접 선택한 모듈만 리뷰 화면에 표시
            for mod_entry in "${USER_SELECTED_MODULES[@]}"; do
                id="${mod_entry%%:*}"
                variant="${mod_entry#*:}"
                if [[ "$id" == "$variant" ]]; then variant=""; fi
                
                name="${MODULE_NAMES[$id]}"
                category="${MODULE_CATEGORIES[$id]}"
                category_display="$(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"

                if [[ -n "$variant" ]]; then
                    item_str="[${category_display}] ${name} (${variant}) : ${mod_entry}"
                else
                    item_str="[${category_display}] ${name} : ${mod_entry}"
                fi
                CONFIRM_ITEMS+="${item_str}\n"

                # Determine whether this item should be selected by default.
                sel=1
                if declare -p PRESET_DEFAULT_SELECTED >/dev/null 2>&1; then
                    sel=${PRESET_DEFAULT_SELECTED["$mod_entry"]:-1}
                fi
                if [[ $sel -ne 0 ]]; then
                    SELECTED_ITEMS+="${item_str}\n"
                fi
            done
            CONFIRM_ITEMS=$(echo -e "$CONFIRM_ITEMS" | sed '/^$/d')
            SELECTED_STR=$(echo -e "$SELECTED_ITEMS" | sed '/^$/d' | tr '\n' ',' | sed 's/,$//')

            clear
             gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" \
                "INSTALLATION REVIEW" "Uncheck items to skip"

            CONFIRMED_SELECTION=""
            EXIT_STATUS=0
            CONFIRMED_SELECTION=$(echo "$CONFIRM_ITEMS" | gum choose --no-limit --selected "$SELECTED_STR" --height 20 --header "최종 설치 목록 확인 (ESC: 뒤로가기)") || EXIT_STATUS=$?

            if [[ $EXIT_STATUS -ne 0 ]]; then
                CURRENT_STATE="MODE_SELECT"
                continue
            fi

            if [[ -z "$CONFIRMED_SELECTION" ]]; then
                gum style --foreground 196 "선택된 항목이 없습니다."
                if gum confirm "초기 화면으로 돌아가시겠습니까?"; then
                    CURRENT_STATE="MODE_SELECT"
                else
                    continue
                fi
            else
                # 사용자가 확정한 모듈 목록을 기반으로 의존성 재해결
                USER_CONFIRMED=()
                while IFS= read -r line; do
                    val=$(echo "$line" | awk -F " : " '{print $2}')
                    if [[ -n "$val" ]]; then
                        USER_CONFIRMED+=("$val")
                    fi
                done <<< "$CONFIRMED_SELECTION"
                
                # 의존성 다시 해결
                FINAL_LIST=()
                INSTALLED=()
                for mod in "${USER_CONFIRMED[@]}"; do
                    resolve_dependencies "$mod" FINAL_LIST
                done
                
                # 설치/DryRun 선택
                ACTION=""
                ACTION=$(gum choose --header "작업을 선택하세요" "🚀 설치 진행 (Execute)" "🔍 시뮬레이션 (Dry Run)" "❌ 취소") || true
                
                if [[ "$ACTION" == *"Dry Run"* ]]; then
                    DRY_RUN=true
                    CURRENT_STATE="INSTALL_RUN"
                elif [[ "$ACTION" == *"Execute"* ]]; then
                    DRY_RUN=false
                    CURRENT_STATE="INSTALL_RUN"
                else
                    CURRENT_STATE="MODE_SELECT"
                fi
            fi
            ;;

        "INSTALL_RUN")
            echo ""
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "🔍 Dry Run 모드: 실제 설치는 수행되지 않습니다."
            else
                log_info "🚀 설치 시작..."
            fi

            needs_sudo=false
            if [[ "$DRY_RUN" != "true" ]]; then
                for mod_entry in "${FINAL_LIST[@]}"; do
                    id="${mod_entry%%:*}"
                    MOD_PATH="${MODULES[$id]}"
                    SCRIPT="$MOD_PATH/install.sh"
                    if script_uses_sudo "$SCRIPT"; then
                        needs_sudo=true
                        break
                    fi
                done

                if [[ "$needs_sudo" == "true" ]]; then
                    if [[ "$IS_TTY" == "true" ]]; then
                        log_info "sudo 권한 확인 중..."
                        sudo -v
                    else
                        # 비대화형 Execute에서 sudo 프롬프트로 멈추는 상황 방지
                        if ! sudo -n true 2>/dev/null; then
                            log_error "비대화형 실행에서 sudo 비밀번호 입력이 필요하여 진행할 수 없습니다."
                            echo "- 해결 1) 터미널에서 실행: ./easy-setup.sh --preset <name> --execute"
                            echo "- 해결 2) 터미널에서 먼저 sudo 캐시 후(비번 1회 입력): sudo -v  그리고 다시 실행"
                            echo "- 해결 3) (선택) sudoers에 NOPASSWD 설정 후 다시 시도"
                            exit 1
                        fi
                    fi
                fi
            fi
            
            for mod_entry in "${FINAL_LIST[@]}"; do
                id="${mod_entry%%:*}"
                variant="${mod_entry#*:}"
                if [[ "$id" == "$variant" ]]; then variant=""; fi

                # Check if this module is marked as selected:false in preset
                # Skip installation if not selected (only in --execute mode with preset)
                if [[ -n "$PRESET_FILE" ]] && declare -p PRESET_DEFAULT_SELECTED >/dev/null 2>&1; then
                    if [[ ${PRESET_DEFAULT_SELECTED["$mod_entry"]:-1} -eq 0 ]]; then
                        echo -e "\n${YELLOW}[SKIP] $mod_entry (selected: false)${NC}"
                        continue
                    fi
                fi

                MOD_PATH="${MODULES[$id]}"
                SCRIPT="$MOD_PATH/install.sh"
                NAME="${MODULE_NAMES[$id]}"
                
                if [[ "$DRY_RUN" == "true" ]]; then
                     echo -e "\n${YELLOW}[Dry Run] would install: $NAME ($id) variant='$variant'${NC}"
                     echo -e "  Script: $SCRIPT"
                else
                    echo -e "\n${BLUE}>>> [$NAME $variant] 설치 중...${NC}"
                    if [[ -x "$SCRIPT" ]]; then
                        # 모듈 실패 시 어떤 모듈이 실패했는지 명확히 출력
                        set +e
                        
                        # VSCode 모듈일 경우 확장 그룹 전달
                        if [[ "$id" == "gui.vscode" && -n "$VSCODE_EXTRAS" ]]; then
                            declare -a vscode_args=()
                            # comma로 구분된 확장 그룹을 공백으로 변환
                            IFS=',' read -ra vscode_args <<< "$VSCODE_EXTRAS"
                            if [[ "${DEBUG_SETUP:-}" == "1" ]]; then
                                bash -x "$SCRIPT" "$variant" "${vscode_args[@]}"
                            else
                                "$SCRIPT" "$variant" "${vscode_args[@]}"
                            fi
                        else
                            if [[ "${DEBUG_SETUP:-}" == "1" ]]; then
                                bash -x "$SCRIPT" "$variant"
                            else
                                "$SCRIPT" "$variant"
                            fi
                        fi
                        
                        rc=$?
                        set -e
                        if [[ $rc -ne 0 ]]; then
                            log_error "모듈 설치 실패: $id${variant:+:$variant} (exit=$rc)"
                            log_error "스크립트: $SCRIPT"
                            exit $rc
                        fi
                        
                        # 설치 성공 후 테스트 실행 (test.sh가 있는 경우)
                        if [[ -f "$MOD_PATH/test.sh" ]]; then
                            echo ""
                            run_module_test "$MOD_PATH" || log_warn "테스트 실패 (계속 진행)"
                        fi
                    else
                        log_warn "실행 스크립트가 없습니다: $SCRIPT"
                    fi
                fi
            done
            echo ""
            log_success "모든 작업이 완료되었습니다!"
            exit 0
            ;;
    esac
done
