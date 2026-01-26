#!/usr/bin/env pwsh
# Discord 설치

$discordPath = "$env:LOCALAPPDATA\Discord\Update.exe"
if (Test-Path $discordPath) {
    Write-LogSuccess "Discord 이미 설치됨"
    exit 0
}

Write-LogInfo "Discord 설치 중..."
Install-WithWinget -Id "Discord.Discord" -Name "Discord" -DryRun:$(Test-DryRunMode)
