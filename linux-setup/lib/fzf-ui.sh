#!/bin/bash
# fzf-ui.sh - fzf 기반 UI 라이브러리

# 현재 디렉토리 설정
FZF_UI_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FZF_UI_CONFIG_DIR="$(cd "$FZF_UI_DIR/../config" && pwd)"

# 전역 변수 (기본값)
UI_TITLE="${UI_TITLE:-Linux Setup Assistant}"
UI_VERSION="${UI_VERSION:-3.0}"
UI_MSG_SELECTED="선택됨"
UI_MSG_NONE="선택된 항목 없음"
ICON_SELECTED="✓"
ICON_UNSELECTED="○"
ICON_DEP="↳"
ICON_SUCCESS="✅"
ICON_ERROR="❌"

# 설정 로드
load_ui_config() {
    local config_file="$FZF_UI_CONFIG_DIR/ui.json"
    [[ ! -f "$config_file" ]] && return 1
    
    # UI 메시지 로드
    UI_TITLE=$(jq -r '.app.title // "Linux Setup Assistant"' "$config_file")
    UI_VERSION=$(jq -r '.app.version // "3.0"' "$config_file")
    UI_MSG_SELECTED=$(jq -r '.messages.selected // "선택됨"' "$config_file")
    UI_MSG_NONE=$(jq -r '.messages.none_selected // "선택된 항목 없음"' "$config_file")
    
    # 아이콘 로드
    ICON_SELECTED=$(jq -r '.icons.selected // "✓"' "$config_file")
    ICON_UNSELECTED=$(jq -r '.icons.unselected // "○"' "$config_file")
    ICON_DEP=$(jq -r '.icons.dependency // "↳"' "$config_file")
    ICON_SUCCESS=$(jq -r '.icons.success // "✅"' "$config_file")
    ICON_ERROR=$(jq -r '.icons.error // "❌"' "$config_file")
    
    return 0
}

# 선택 파일 (임시)
init_selected_file() {
    SELECTED_FILE=$(mktemp /tmp/easy-setup-selected.XXXXXX)
    # 종료 시 정리
    trap "rm -f '$SELECTED_FILE' 2>/dev/null" EXIT
}

# 선택 목록 관리
add_selected() {
    local item="$1"
    [[ -z "$SELECTED_FILE" ]] && return
    grep -qxF "$item" "$SELECTED_FILE" 2>/dev/null || echo "$item" >> "$SELECTED_FILE"
}

remove_selected() {
    local item="$1"
    [[ -z "$SELECTED_FILE" || ! -f "$SELECTED_FILE" ]] && return
    local tmp
    tmp=$(mktemp)
    grep -vxF "$item" "$SELECTED_FILE" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$SELECTED_FILE"
}

toggle_selected() {
    local item="$1"
    if grep -qxF "$item" "$SELECTED_FILE" 2>/dev/null; then
        remove_selected "$item"
    else
        add_selected "$item"
    fi
}

is_selected() {
    local item="$1"
    [[ -f "$SELECTED_FILE" ]] && grep -qxF "$item" "$SELECTED_FILE" 2>/dev/null
}

get_selected_list() {
    [[ -f "$SELECTED_FILE" ]] && cat "$SELECTED_FILE" 2>/dev/null || echo ""
}

# 모듈 캐시 (폴더명 -> meta 정보)
declare -A MODULE_CACHE_ID
declare -A MODULE_CACHE_NAME
declare -A MODULE_CACHE_VARIANTS

# 모듈 캐시 초기화
init_module_cache() {
    local modules_dir="$1"
    MODULE_CACHE_ID=()
    MODULE_CACHE_NAME=()
    MODULE_CACHE_VARIANTS=()
    
    while IFS= read -r meta_file; do
        [[ -z "$meta_file" ]] && continue
        local folder_name
        folder_name=$(basename "$(dirname "$meta_file")")
        
        MODULE_CACHE_ID["$folder_name"]=$(jq -r '.id // ""' "$meta_file" 2>/dev/null)
        MODULE_CACHE_NAME["$folder_name"]=$(jq -r '.name // "Unknown"' "$meta_file" 2>/dev/null)
        MODULE_CACHE_VARIANTS["$folder_name"]=$(jq -r '.variants[]? // empty' "$meta_file" 2>/dev/null | tr '\n' ' ')
    done < <(find "$modules_dir" -name "meta.json" -type f 2>/dev/null)
}

get_selected_count() {
    if [[ -f "$SELECTED_FILE" && -s "$SELECTED_FILE" ]]; then
        wc -l < "$SELECTED_FILE" | tr -d ' '
    else
        echo "0"
    fi
}

# 트리 형태로 모듈 목록 생성 (캐시 사용)
build_tree_list() {
    local modules_dir="$1"
    local categories_json="$2"
    local output=""
    
    [[ ! -f "$categories_json" ]] && { echo ""; return; }
    
    # 캐시가 비어있으면 초기화
    [[ ${#MODULE_CACHE_ID[@]} -eq 0 ]] && init_module_cache "$modules_dir"
    
    # 카테고리 순서대로 처리
    local cats
    cats=$(jq -r 'to_entries | sort_by(.value.order // 99) | .[].key' "$categories_json" 2>/dev/null) || return
    
    for cat in $cats; do
        local cat_name
        cat_name=$(jq -r ".${cat}.name // \"$cat\"" "$categories_json")
        output+="$cat_name\n"
        
        # 서브카테고리가 있는 경우
        local has_subcats
        has_subcats=$(jq -r ".${cat}.subcategories // empty" "$categories_json")
        
        if [[ -n "$has_subcats" && "$has_subcats" != "null" ]]; then
            local subcats
            subcats=$(jq -r ".${cat}.subcategories | keys[]" "$categories_json" 2>/dev/null) || continue
            
            for subcat in $subcats; do
                local subcat_name
                subcat_name=$(jq -r ".${cat}.subcategories.${subcat}.name // \"$subcat\"" "$categories_json")
                output+="  $subcat_name\n"
                
                local modules
                modules=$(jq -r ".${cat}.subcategories.${subcat}.modules[]? // empty" "$categories_json" 2>/dev/null) || continue
                
                for mod in $modules; do
                    # 캐시에서 읽기
                    local mod_id="${MODULE_CACHE_ID[$mod]:-}"
                    local mod_name="${MODULE_CACHE_NAME[$mod]:-}"
                    local variants="${MODULE_CACHE_VARIANTS[$mod]:-}"
                    
                    [[ -z "$mod_id" ]] && continue
                    
                    if [[ -n "$variants" ]]; then
                        for v in $variants; do
                            local key="${mod_id}:${v}"
                            local mark="$ICON_UNSELECTED"
                            is_selected "$key" && mark="$ICON_SELECTED"
                            output+="    $mark $mod_name [$v]|${key}\n"
                        done
                    else
                        local mark="$ICON_UNSELECTED"
                        is_selected "$mod_id" && mark="$ICON_SELECTED"
                        output+="    $mark $mod_name|${mod_id}\n"
                    fi
                done
            done
        else
            # 직접 모듈 목록
            local modules
            modules=$(jq -r ".${cat}.modules[]? // empty" "$categories_json" 2>/dev/null) || continue
            
            for mod in $modules; do
                # 캐시에서 읽기
                local mod_id="${MODULE_CACHE_ID[$mod]:-}"
                local mod_name="${MODULE_CACHE_NAME[$mod]:-}"
                local variants="${MODULE_CACHE_VARIANTS[$mod]:-}"
                
                [[ -z "$mod_id" ]] && continue
                
                if [[ -n "$variants" ]]; then
                    for v in $variants; do
                        local key="${mod_id}:${v}"
                        local mark="$ICON_UNSELECTED"
                        is_selected "$key" && mark="$ICON_SELECTED"
                        output+="    $mark $mod_name [$v]|${key}\n"
                    done
                else
                    local mark="$ICON_UNSELECTED"
                    is_selected "$mod_id" && mark="$ICON_SELECTED"
                    output+="    $mark $mod_name|${mod_id}\n"
                fi
            done
        fi
    done
    
    echo -e "$output"
}

# 메인 fzf UI 실행
run_fzf_selector() {
    local modules_dir="$1"
    local categories_file="$2"
    local preview_script="$3"
    
    # 환경변수로 preview에 전달
    export EASY_SETUP_MODULES_DIR="$modules_dir"
    export EASY_SETUP_SELECTED_FILE="$SELECTED_FILE"
    
    while true; do
        # 트리 목록 생성
        local tree_list
        tree_list=$(build_tree_list "$modules_dir" "$categories_file")
        
        [[ -z "$tree_list" ]] && { echo "모듈 목록을 생성할 수 없습니다."; return 1; }
        
        # fzf 실행
        local selected exit_code=0
        selected=$(echo -e "$tree_list" | fzf \
            --ansi \
            --multi \
            --reverse \
            --header "$UI_TITLE v$UI_VERSION | Tab: 선택 | Enter: 확정 | Esc: 취소" \
            --header-first \
            --preview "bash '$preview_script' {}" \
            --preview-window "right:45%:wrap" \
            --bind "tab:toggle+down" \
            --bind "shift-tab:toggle+up" \
            --bind "ctrl-a:select-all" \
            --bind "ctrl-d:deselect-all" \
            --delimiter '\|' \
            --with-nth 1 \
            --pointer "▶" \
            --marker "✓" \
            --color "header:yellow,pointer:green,marker:green" \
            2>/dev/null) || exit_code=$?
        
        # Esc 누름 (exit code 130 또는 1)
        if [[ $exit_code -ne 0 && -z "$selected" ]]; then
            return 1
        fi
        
        # 선택 없이 Enter (확정)
        [[ -z "$selected" ]] && break
        
        # 선택된 항목들 토글
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local item_id
            item_id=$(echo "$line" | awk -F'|' '{print $2}')
            [[ -n "$item_id" ]] && toggle_selected "$item_id"
        done <<< "$selected"
    done
    
    return 0
}

# fzf로 프리셋 선택
select_preset_fzf() {
    local presets_dir="$1"
    
    local preset_list=""
    while IFS= read -r pf; do
        [[ -z "$pf" ]] && continue
        local name desc
        name=$(jq -r '.name // "Unknown"' "$pf" 2>/dev/null)
        desc=$(jq -r '.description // ""' "$pf" 2>/dev/null)
        preset_list+="$name|$(basename "$pf")|$desc\n"
    done < <(find "$presets_dir" -name "*.json" 2>/dev/null | sort)
    
    [[ -z "$preset_list" ]] && { echo ""; return 1; }
    
    local selected
    selected=$(echo -e "$preset_list" | fzf \
        --ansi \
        --reverse \
        --header "📦 프리셋 선택 | Enter: 선택 | Esc: 취소" \
        --header-first \
        --delimiter '\|' \
        --with-nth 1,3 \
        --preview "jq -r '.modules[] | \"  \" + .id + (if .params.version then \":\" + .params.version else \"\" end)' '$presets_dir/{2}' 2>/dev/null || echo '프리뷰 불가'" \
        --preview-window "right:40%:wrap" \
        2>/dev/null) || return 1
    
    [[ -z "$selected" ]] && return 1
    
    echo "$selected" | awk -F'|' '{print $2}'
}

# 확인 다이얼로그
confirm_install_fzf() {
    local count
    count=$(get_selected_count)
    
    echo -e "\n\033[1;33m━━━ 설치 확인 ━━━\033[0m"
    echo -e "선택된 모듈: \033[1;32m${count}개\033[0m\n"
    
    get_selected_list | while read -r item; do
        echo -e "  $ICON_SELECTED $item"
    done
    
    echo ""
    local choice
    choice=$(echo -e "🚀 설치 시작\n🔍 시뮬레이션 (Dry Run)\n❌ 취소" | fzf \
        --ansi \
        --reverse \
        --header "실행 방식 선택" \
        --height 10 \
        2>/dev/null) || true
    
    case "$choice" in
        *"설치"*) echo "execute" ;;
        *"시뮬레이션"*) echo "dry-run" ;;
        *) echo "cancel" ;;
    esac
}
