#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/distro.sh"

detect_os

# 리눅스 네이티브 VSCode 경로 확인
LINUX_CODE_BIN="/usr/bin/code"
if [[ ! -x "$LINUX_CODE_BIN" ]]; then
    # 다른 경로(예: /bin/code)에 있을 수 있으므로 한번 더 확인
    if command -v code &>/dev/null; then
        potential_path=$(command -v code)
        if [[ "$potential_path" != /mnt/* ]]; then
            LINUX_CODE_BIN="$potential_path"
        fi
    fi
fi

# VSCode 설치 (리눅스용이 없는 경우에만)
if [[ -x "$LINUX_CODE_BIN" ]]; then
    echo "✅ 리눅스용 VS Code가 이미 설치됨: $LINUX_CODE_BIN"
else
    echo "📥 리눅스용 VS Code 설치 시작..."
    
    if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg

        sudo apt update
        sudo DEBIAN_FRONTEND=noninteractive apt install -y code
        
    elif [[ "$OS_ID" == "fedora" ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
             echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
        fi
        sudo dnf install -y code
    else
        echo "❌ 지원하지 않는 OS입니다: $OS_ID"
        exit 1
    fi
    LINUX_CODE_BIN="/usr/bin/code"
    echo "✅ 리눅스용 VS Code 설치 완료"
fi

# VSCode 확장 그룹 설치
install_vscode_extensions() {
    local -a profiles=()
    for p in "$@"; do
        [[ -n "$p" ]] && profiles+=("$p")
    done
    
    profiles=("base" "${profiles[@]}")
    echo "VSCode 확장 설치 그룹: ${profiles[*]}"
    
    # 확실한 리눅스용 바이너리 사용
    local code_cmd="$LINUX_CODE_BIN"
    if [[ ! -x "$code_cmd" ]]; then
        echo "❌ 리눅스용 code 바이너리를 찾을 수 없습니다. 확장을 설치할 수 없습니다."
        return 1
    fi
    
    # 모든 확장 수집
    local -a all_extensions=()
    for profile in "${profiles[@]}"; do
        local ext_file="$SCRIPT_DIR/extensions/${profile}.json"
        if [[ -f "$ext_file" ]]; then
            while IFS= read -r ext; do
                [[ -n "$ext" ]] && all_extensions+=("$ext")
            done < <(jq -r '.extensions[]' "$ext_file" 2>/dev/null || true)
        else
            echo "⚠️  확장 그룹 파일을 찾을 수 없습니다: $ext_file"
        fi
    done
    
    if [[ ${#all_extensions[@]} -eq 0 ]]; then
        echo "설치할 확장이 없습니다."
        return
    fi
    
    local -a unique_extensions=($(printf '%s\n' "${all_extensions[@]}" | sort -u))
    echo "총 ${#unique_extensions[@]}개 확장 설치 시도 중..."
    
    local installed=0
    for ext in "${unique_extensions[@]}"; do
        echo "설치 중: $ext"
        # --user-data-dir을 임시로 주어 샌드박스 이슈 회피 (필요 시)
        if "$code_cmd" --install-extension "$ext" --force; then
            ((installed++)) || true
        else
            echo "❌ 확장 설치 실패: $ext"
        fi
    done
    
    echo "✅ VSCode 확장 설치 완료: ${installed}개 설치됨"
}

# 프로필 인자 처리
if [[ $# -gt 0 ]]; then
    install_vscode_extensions "$@"
fi