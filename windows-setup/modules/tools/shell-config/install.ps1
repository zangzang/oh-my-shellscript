#!/usr/bin/env pwsh
# PowerShell 프로필 설정

$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
}

$profileContent = @"
# Oh My Posh
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config `$env:POSH_THEMES_PATH\jandedobbeleer.omp.json | Invoke-Expression
}

# Terminal Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# zoxide
if (Get-Command z -ErrorAction SilentlyContinue) {
    zoxide init powershell | Invoke-Expression
}

# PSReadLine 설정 (자동 완성 등)
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# Aliases
Set-Alias g git
Set-Alias l ls
"@

if (Test-DryRunMode) {
    Write-LogInfo "[DryRun] PowerShell 프로필 설정 작성 (`$PROFILE)"
    Write-Host "--- Profile Content ---" -ForegroundColor DarkGray
    Write-Host $profileContent -ForegroundColor DarkGray
} else {
    Write-LogInfo "PowerShell 프로필 작성 중... ($PROFILE)"
    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force
    Write-LogSuccess "프로필 설정 완료"
}
