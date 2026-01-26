#!/usr/bin/env pwsh
# Git 설치

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Git 이미 설치됨"
    Write-Host "  버전: $(git --version)"
    exit 0
}

Write-LogInfo "Git 설치 중..."
Install-WithWinget -Id "Git.Git" -Name "Git" -DryRun:$(Test-DryRunMode)
