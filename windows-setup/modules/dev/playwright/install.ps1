#!/usr/bin/env pwsh
# Playwright Setup

# 1. Check Prerequisites (.NET SDK)
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-LogError ".NET SDK가 설치되어 있지 않습니다. Playwright 설치를 중단합니다."
    exit 1
}

Write-LogInfo "Playwright 설정 시작..."

# 2. Install Playwright CLI Global Tool
Write-LogInfo "Playwright CLI 도구 확인 중..."
$toolList = dotnet tool list --global
if ($toolList -match "Microsoft.Playwright.CLI") {
    Write-LogSuccess "Playwright CLI가 이미 설치되어 있습니다."
}
else {
    Write-LogInfo "Playwright CLI 설치 중..."
    dotnet tool install --global Microsoft.Playwright.CLI
    
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "Playwright CLI 설치 완료"
    }
    else {
        Write-LogError "Playwright CLI 설치 실패"
        exit 1
    }
}

# 3. Configure Environment Variable (Persistent)
$metaPath = Join-Path $PSScriptRoot "meta.json"
if (Test-Path $metaPath) {
    $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
    $BROWSERS_PATH = $meta.configuration.BROWSERS_PATH
}

if ([string]::IsNullOrWhiteSpace($BROWSERS_PATH)) {
    Write-LogWarn "BROWSERS_PATH not defined in meta.json. Using default."
    $BROWSERS_PATH = "C:\Shared\PlaywrightBrowsers"
}

# Create directory if it doesn't exist
if (-not (Test-Path $BROWSERS_PATH)) {
    try {
        New-Item -Path $BROWSERS_PATH -ItemType Directory -Force | Out-Null
        Write-LogSuccess "브라우저 저장 경로 생성됨: $BROWSERS_PATH"
    }
    catch {
        Write-LogError "경로 생성 실패: $_"
        exit 1
    }
}

# Set persistent environment variable using project helper
# This handles backup and session update automatically
Set-EnvironmentVariableSafe -Name "PLAYWRIGHT_BROWSERS_PATH" -Value $BROWSERS_PATH -Scope "User"

# 4. Install Browsers
Write-LogInfo "Playwright 브라우저 설치 중..."
try {
    # Ensure the environment variable is active for this command even if Set-EnvironmentVariableSafe missed it (redundancy)
    $env:PLAYWRIGHT_BROWSERS_PATH = $BROWSERS_PATH
    
    playwright install
    
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "Playwright 브라우저 설치 완료"
    }
    else {
        Write-LogWarn "Playwright 브라우저 설치 중 오류가 발생했을 수 있습니다."
    }
}
catch {
    Write-LogError "브라우저 설치 실행 중 오류: $_"
}
