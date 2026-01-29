#!/usr/bin/env pwsh
# zoxide 설치

if (Get-Command z -ErrorAction SilentlyContinue) {
    Write-LogSuccess "zoxide 이미 설치됨"
    exit 0
}

Write-LogInfo "zoxide 설치 중..."
Install-WithWinget -Id "ajeetdsouza.zoxide" -Name "zoxide" -DryRun:$(Test-DryRunMode)
