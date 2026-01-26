#!/usr/bin/env pwsh
# Windows Terminal 설치

if (Get-Command wt -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Windows Terminal 이미 설치됨"
    exit 0
}

Write-LogInfo "Windows Terminal 설치 중..."
Install-WithWinget -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal" -DryRun:$(Test-DryRunMode)
