#!/bin/bash
set -e

export CARGO_HOME="$HOME/.cargo"

if command -v cargo &>/dev/null; then
    echo "Rust 이미 설치됨."
    exit 0
fi

echo "Rust 설치 중..."
if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo "Rust 설치 완료."
else
    echo "Rust 설치 실패"
    exit 1
fi
