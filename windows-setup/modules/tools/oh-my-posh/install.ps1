#!/usr/bin/env pwsh
# Oh My Posh 설치

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Oh My Posh 이미 설치됨"
    Write-Host "  버전: $(oh-my-posh version)"
    exit 0
}

Write-LogInfo "Oh My Posh 설치 중..."
Install-WithWinget -Id "JanDeDobbeleer.OhMyPosh" -Name "Oh My Posh" -DryRun:$(Test-DryRunMode)
