#!/usr/bin/env pwsh
# Terminal Icons 설치

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Write-LogSuccess "Terminal-Icons 이미 설치됨"
    exit 0
}

Write-LogInfo "Terminal-Icons 모듈 설치 중..."
Install-PowerShellModule -Name "Terminal-Icons" -DryRun:$(Test-DryRunMode)
