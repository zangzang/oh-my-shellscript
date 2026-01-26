#!/usr/bin/env pwsh
# Notion 설치

if (Get-Command notion -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Notion 이미 설치됨"
    exit 0
}

Write-LogInfo "Notion 설치 중..."
Install-WithWinget -Id "Notion.Notion" -Name "Notion" -DryRun:$(Test-DryRunMode)
