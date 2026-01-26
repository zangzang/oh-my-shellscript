#!/usr/bin/env pwsh
# Java (OpenJDK) 설치

if (Get-Command java -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Java 이미 설치됨"
    Write-Host "  버전: $(java -version 2>&1 | Select-Object -First 1)"
    exit 0
}

Write-LogInfo "Java (OpenJDK 17) 설치 중..."
Install-WithWinget -Id "Eclipse.Temurin.17" -Name "Java (OpenJDK 17)" -DryRun:$(Test-DryRunMode)
