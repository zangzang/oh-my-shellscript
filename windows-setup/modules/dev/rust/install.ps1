#!/usr/bin/env pwsh
# Rust 설치

if (Get-Command rustc -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Rust 이미 설치됨"
    Write-Host "  버전: $(rustc --version)"
    exit 0
}

Write-LogInfo "Rust 설치 중..."
# rustup-init.exe를 다운로드하여 실행
$tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "rustup-init.exe")
Invoke-WebRequest -Uri "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" `
    -OutFile $tempFile -UseBasicParsing

& $tempFile -y
Remove-Item $tempFile
