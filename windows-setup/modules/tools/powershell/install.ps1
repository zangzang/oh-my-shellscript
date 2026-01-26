#!/usr/bin/env pwsh
# PowerShell 7 설치

$ps7Path = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (Test-Path $ps7Path) {
    Write-LogSuccess "PowerShell 7 이미 설치됨"
    Write-Host "  경로: $ps7Path"
    exit 0
}

Write-LogInfo "PowerShell 7 설치 중..."
Install-WithWinget -Id "Microsoft.PowerShell" -Name "PowerShell 7" -DryRun:$(Test-DryRunMode)
