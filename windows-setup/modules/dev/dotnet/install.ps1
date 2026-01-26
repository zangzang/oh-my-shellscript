#!/usr/bin/env pwsh
# .NET SDK 설치

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Write-LogSuccess ".NET SDK 이미 설치됨"
    Write-Host "  버전: $(dotnet --version)"
    exit 0
}

Write-LogInfo ".NET SDK 설치 중..."
Install-WithWinget -Id "Microsoft.DotNet.SDK.8" -Name ".NET SDK 8" -DryRun:$(Test-DryRunMode)
