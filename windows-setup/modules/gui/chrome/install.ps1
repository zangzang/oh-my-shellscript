#!/usr/bin/env pwsh
# Chrome 설치

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    Write-LogSuccess "Chrome 이미 설치됨"
    Write-Host "  경로: $chromePath"
    exit 0
}

Write-LogInfo "Chrome 설치 중..."
Install-WithWinget -Id "Google.Chrome" -Name "Google Chrome" -DryRun:$(Test-DryRunMode)
