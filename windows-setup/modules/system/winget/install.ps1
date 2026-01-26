#!/usr/bin/env pwsh
# Winget는 Windows 11에 기본 포함됨

if (Test-Winget) {
    Write-LogSuccess "Winget 이미 설치됨"
    exit 0
}

Write-LogError "Winget을 찾을 수 없습니다. Windows 11 최신 버전으로 업데이트하세요."
exit 1
