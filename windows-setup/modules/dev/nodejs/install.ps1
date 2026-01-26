#!/usr/bin/env pwsh
# Node.js 설치

if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Node.js 이미 설치됨"
    Write-Host "  버전: $(node --version)"
    exit 0
}

Write-LogInfo "Node.js 설치 중..."
Install-WithWinget -Id "OpenJS.NodeJS" -Name "Node.js" -DryRun:$(Test-DryRunMode)
