#!/bin/bash
# preview.sh - fzf 프리뷰 스크립트 (단순화 버전)

LINE="${1:-}"

# 환경변수에서 경로 가져오기
MODULES_DIR="${EASY_SETUP_MODULES_DIR:-}"
SELECTED_FILE="${EASY_SETUP_SELECTED_FILE:-}"

# 아이콘
ICON_SELECTED="✓"
ICON_DEP="↳"

# 선택된 항목 표시
echo -e "\033[1;36m━━━ 선택됨 ━━━\033[0m"
if [[ -f "$SELECTED_FILE" && -s "$SELECTED_FILE" ]]; then
    count=$(wc -l < "$SELECTED_FILE" 2>/dev/null | tr -d ' ')
    echo -e "\033[90m($count 개)\033[0m"
    head -20 "$SELECTED_FILE" 2>/dev/null | while IFS= read -r sel; do
        echo -e "  \033[32m$ICON_SELECTED\033[0m $sel"
    done
else
    echo -e "  \033[90m없음\033[0m"
fi

echo ""
echo -e "\033[1;33m━━━ 정보 ━━━\033[0m"

# 항목 ID 추출 (| 뒤)
ITEM_ID="${LINE##*|}"

# 카테고리 헤더면 스킵
if [[ -z "$ITEM_ID" || "$ITEM_ID" == "$LINE" || ! "$ITEM_ID" == *.* ]]; then
    echo -e "\033[90m모듈을 선택하세요\033[0m"
    exit 0
fi

# variant 분리
if [[ "$ITEM_ID" == *:* ]]; then
    MOD_ID="${ITEM_ID%%:*}"
    VARIANT="${ITEM_ID#*:}"
else
    MOD_ID="$ITEM_ID"
    VARIANT=""
fi

# 폴더명 추출 (dev.java -> java)
MOD_FOLDER="${MOD_ID##*.}"

# meta.json 찾기
META_FILE=""
if [[ -d "$MODULES_DIR" ]]; then
    META_FILE=$(find "$MODULES_DIR" -maxdepth 3 -path "*/${MOD_FOLDER}/meta.json" -type f 2>/dev/null | head -1)
fi

if [[ -f "$META_FILE" ]]; then
    NAME=$(jq -r '.name // "Unknown"' "$META_FILE" 2>/dev/null)
    DESC=$(jq -r '.description // ""' "$META_FILE" 2>/dev/null)
    
    if [[ -n "$VARIANT" ]]; then
        echo -e "\033[1m$NAME\033[0m \033[36m[$VARIANT]\033[0m"
    else
        echo -e "\033[1m$NAME\033[0m"
    fi
    [[ -n "$DESC" ]] && echo -e "\033[90m$DESC\033[0m"
    
    # 의존성
    DEPS=$(jq -r '.requires[]? // empty' "$META_FILE" 2>/dev/null)
    if [[ -n "$DEPS" ]]; then
        echo -e "\n\033[33m의존성:\033[0m"
        echo "$DEPS" | while read -r d; do
            [[ -n "$d" ]] && echo "  $ICON_DEP $d"
        done
    fi
else
    echo -e "\033[90m$MOD_ID\033[0m"
fi
