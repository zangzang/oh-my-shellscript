#!/bin/bash
set -e

if [ -d "$HOME/sts" ] && [ -f "$HOME/sts/SpringToolSuite4" ]; then
    echo "Spring Tool Suite 이미 설치됨."
else
    echo "Spring Tool Suite 설치 중..."
    
    # 최신 STS 다운로드 URL (버전에 따라 업데이트 필요)
    STS_VERSION="4.21.1.RELEASE"
    STS_URL="https://download.springsource.com/release/STS4/4.21.1.RELEASE/dist/e4.30/spring-tool-suite-4-4.21.1.RELEASE-e4.30.0-linux.gtk.x86_64.tar.gz"
    
    tmp_base="${TMPDIR:-/tmp}"
    if ! mkdir -p "$tmp_base" 2>/dev/null; then
        tmp_base="$HOME/.cache"
        mkdir -p "$tmp_base"
    fi

    tmpdir="$(mktemp -d -p "$tmp_base" sts.XXXXXX)"
    cleanup() { rm -rf "$tmpdir"; }
    trap cleanup EXIT

    wget -O "$tmpdir/sts.tar.gz" "$STS_URL"

    mkdir -p "$tmpdir/extract"
    # 일부 파일시스템에서 utime/chmod가 막혀 tar가 실패할 수 있어 옵션으로 회피
    tar -xzf "$tmpdir/sts.tar.gz" -C "$tmpdir/extract" \
        --touch --no-same-owner --no-same-permissions

    extracted_dir="$(find "$tmpdir/extract" -maxdepth 1 -type d -name 'sts-*' | head -n 1)"
    if [[ -z "$extracted_dir" ]]; then
        echo "❌ STS 압축 해제 결과를 찾지 못했습니다."
        exit 1
    fi

    rm -rf "$HOME/sts"
    mv "$extracted_dir" "$HOME/sts"
    
    # 데스크톱 엔트리 디렉토리 생성
    mkdir -p "$HOME/.local/share/applications"
    
    # 데스크톱 엔트리 생성
    cat > "$HOME/.local/share/applications/sts.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Spring Tool Suite
Comment=Eclipse-based IDE for Spring development
Exec=$HOME/sts/SpringToolSuite4
Icon=$HOME/sts/icon.xpm
Terminal=false
Categories=Development;IDE;
EOF
    
    chmod +x "$HOME/.local/share/applications/sts.desktop"
    
    echo "Spring Tool Suite 설치 완료"
    echo "위치: $HOME/sts"
fi
