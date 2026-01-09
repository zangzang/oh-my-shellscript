#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# VSCode 설치
if command -v code &>/dev/null; then
    echo "VS Code 이미 설치됨."
else
    echo "VS Code 설치 중..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg

    sudo apt install -y apt-transport-https
    sudo apt update
    
    # DEBIAN_FRONTEND=noninteractive로 프롬프트 자동 처리
    sudo DEBIAN_FRONTEND=noninteractive apt install -y code
    echo "VS Code 설치 완료"
fi

# VSCode 확장 그룹 설치
install_vscode_extensions() {
    local -a profiles=("$@")
    
    # base는 항상 포함
    profiles=("base" "${profiles[@]}")
    
    echo "VSCode 확장 설치: ${profiles[*]}"
    
    # 모든 확장 수집 (중복 제거용)
    local -a all_extensions=()
    for profile in "${profiles[@]}"; do
        local ext_file="$SCRIPT_DIR/extensions/${profile}.json"
        if [[ -f "$ext_file" ]]; then
            # jq로 확장 목록 추출
            while IFS= read -r ext; do
                all_extensions+=("$ext")
            done < <(jq -r '.extensions[]' "$ext_file" 2>/dev/null || true)
        else
            echo "경고: 확장 그룹을 찾을 수 없습니다: $profile"
        fi
    done
    
    if [[ ${#all_extensions[@]} -eq 0 ]]; then
        echo "설치할 확장이 없습니다."
        return
    fi
    
    # 중복 제거
    local -a unique_extensions=($(printf '%s\n' "${all_extensions[@]}" | sort -u))
    
    echo "총 ${#unique_extensions[@]}개 확장 설치 중..."
    local installed=0
    for ext in "${unique_extensions[@]}"; do
        if code --install-extension "$ext" --force 2>/dev/null; then
            ((installed++)) || true
        else
            echo "경고: 확장 설치 실패 - $ext"
        fi
    done
    
    echo "VSCode 확장 설치 완료: ${installed}개 설치됨"
}

# 프로필 인자 처리
if [[ $# -gt 0 ]]; then
    install_vscode_extensions "$@"
fi
