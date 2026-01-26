#!/usr/bin/env pwsh
# Docker Desktop 설치

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Docker 이미 설치됨"
    Write-Host "  버전: $(docker --version)"
    exit 0
}

Write-LogInfo "Docker Desktop 설치 중..."
Install-WithWinget -Id "Docker.DockerDesktop" -Name "Docker Desktop" -DryRun:$(Test-DryRunMode)
