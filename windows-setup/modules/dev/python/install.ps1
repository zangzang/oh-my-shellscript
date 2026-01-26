#!/usr/bin/env pwsh
# Python 설치

if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Python 이미 설치됨"
    Write-Host "  버전: $(python --version)"
    exit 0
}

Write-LogInfo "Python 설치 중..."
Install-WithWinget -Id "Python.Python.3.12" -Name "Python" -DryRun:$(Test-DryRunMode)
