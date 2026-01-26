#!/usr/bin/env pwsh
# gsudo 설치

if (Get-Command gsudo -ErrorAction SilentlyContinue) {
    Write-LogSuccess "gsudo 이미 설치됨"
    Write-Host "  버전: $(gsudo --version)"
    exit 0
}

Write-LogInfo "gsudo 설치 중..."
Install-WithWinget -Id "gerardog.gsudo" -Name "gsudo" -DryRun:$(Test-DryRunMode)
