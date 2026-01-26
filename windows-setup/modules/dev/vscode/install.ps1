#!/usr/bin/env pwsh
# Visual Studio Code 설치

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-LogSuccess "VS Code 이미 설치됨"
    Write-Host "  경로: $(Get-Command code | Select-Object -ExpandProperty Source)"
    exit 0
}

Write-LogInfo "VS Code 설치 중..."
Install-WithWinget -Id "Microsoft.VisualStudioCode" -Name "Visual Studio Code" -DryRun:$(Test-DryRunMode)
