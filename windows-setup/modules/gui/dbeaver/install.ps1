#!/usr/bin/env pwsh
# DBeaver 설치

if (Get-Command dbeaver -ErrorAction SilentlyContinue) {
    Write-LogSuccess "DBeaver 이미 설치됨"
    exit 0
}

Write-LogInfo "DBeaver 설치 중..."
Install-WithWinget -Id "dbeaver.dbeaver" -Name "DBeaver" -DryRun:$(Test-DryRunMode)
