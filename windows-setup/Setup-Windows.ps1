#!/usr/bin/env pwsh
<#
.SYNOPSIS
Windows 개발 환경 자동 설치 및 설정

.DESCRIPTION
Git, VSCode, Node.js, Python, Java, .NET, Docker 등
다양한 개발 도구를 선택하여 자동 설치합니다.

.PARAMETER Preset
프리셋 파일명 지정 (base, dotnet-dev, java-dev 등)

.PARAMETER Module
특정 모듈만 설치 (dev.git, dev.nodejs 등)

.PARAMETER DryRun
실제 설치 없이 실행 계획만 표시

.EXAMPLE
.\Setup-Windows.ps1
인터랙티브 메뉴 모드

.\Setup-Windows.ps1 -Preset dotnet-dev
.NET 개발자 프리셋 설치

.\Setup-Windows.ps1 -DryRun
설치 계획 미리보기
#>

#Requires -Version 7.0
#Requires -RunAsAdministrator

param(
    [string]$Preset,
    [string[]]$Module,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# 스크립트 디렉토리 설정
$scriptDir = $PSScriptRoot
if (-not $scriptDir -or $scriptDir -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
if (-not $scriptDir -or $scriptDir -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $scriptDir -or $scriptDir -eq "") {
    $scriptDir = Get-Location
}

# 절대 경로로 변환
$scriptDir = Resolve-Path -LiteralPath $scriptDir -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path
if (-not $scriptDir) {
    Write-Error "스크립트 디렉토리를 결정할 수 없습니다"
    exit 1
}

# 라이브러리 로드
$libPath = Join-Path $scriptDir "lib"
$corePath = Join-Path $libPath "core.psm1"
$uiPath = Join-Path $libPath "ui.psm1"
$installerPath = Join-Path $libPath "installer.psm1"

# 디버그 정보
Write-Host "스크립트 위치: $scriptDir" -ForegroundColor DarkGray
Write-Host "라이브러리 경로: $libPath" -ForegroundColor DarkGray

if (-not (Test-Path $corePath)) {
    Write-Error "필수 라이브러리를 찾을 수 없습니다: $corePath"
    Write-Host ""
    Write-Host "디버그 정보:" -ForegroundColor Yellow
    Write-Host "  PSScriptRoot: $PSScriptRoot"
    Write-Host "  MyCommand.Definition: $($MyInvocation.MyCommand.Definition)"
    Write-Host "  MyCommand.Path: $($MyInvocation.MyCommand.Path)"
    Write-Host "  Current Location: $(Get-Location)"
    Write-Host ""
    
    if (Test-Path $libPath) {
        Write-Host "라이브러리 디렉토리 내용:" -ForegroundColor Yellow
        Get-ChildItem $libPath | ForEach-Object { Write-Host "  - $($_.Name)" }
    } else {
        Write-Host "라이브러리 디렉토리 자체가 없습니다: $libPath" -ForegroundColor Red
        if (Test-Path $scriptDir) {
            Write-Host ""
            Write-Host "스크립트 디렉토리 내용:" -ForegroundColor Yellow
            Get-ChildItem $scriptDir | ForEach-Object { Write-Host "  - $($_.Name)" }
        }
    }
    exit 1
}

Import-Module $corePath -Global
Import-Module $uiPath -Global
Import-Module $installerPath -Global

# Dry Run 모드 설정
if ($DryRun) {
    Set-DryRunMode -Enabled
}

function Get-ModuleMetadata {
    param(
        [string]$ModuleId
    )
    
    $category = $ModuleId.Split('.')[0]
    $name = $ModuleId.Split('.')[1]
    $metaPath = Join-Path $scriptDir "modules" $category $name "meta.json"
    
    if (Test-Path $metaPath) {
        return Get-Content $metaPath -Raw | ConvertFrom-Json
    }
    return $null
}

function Get-AllModules {
    $modules = @()
    $modulesDir = Join-Path $scriptDir "modules"
    
    if (-not (Test-Path $modulesDir)) {
        return $modules
    }
    
    Get-ChildItem -Path $modulesDir -Directory | ForEach-Object {
        $category = $_.Name
        Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
            $moduleName = $_.Name
            $metaPath = Join-Path $_.FullName "meta.json"
            
            if (Test-Path $metaPath) {
                $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
                $modules += $meta
            }
        }
    }
    
    return $modules
}

function Get-PresetModules {
    param(
        [string]$PresetName
    )
    
    $presetPath = Join-Path $scriptDir "presets" "$PresetName.json"
    
    if (-not (Test-Path $presetPath)) {
        Write-LogError "프리셋을 찾을 수 없습니다: $PresetName"
        return $null
    }
    
    $preset = Get-Content $presetPath -Raw | ConvertFrom-Json
    return $preset.modules
}

function Install-Modules {
    param(
        [array]$ModuleIds
    )
    
    $installed = @()
    $failed = @()
    
    foreach ($moduleId in $ModuleIds) {
        Write-Section "설치 중: $moduleId"
        
        try {
            $category = $moduleId.Split('.')[0]
            $name = $moduleId.Split('.')[1]
            $installPath = Join-Path $scriptDir "modules" $category $name "install.ps1"
            
            if (-not (Test-Path $installPath)) {
                Write-LogWarn "설치 스크립트를 찾을 수 없습니다: $moduleId"
                $failed += $moduleId
                continue
            }
            
            & $installPath
            $installed += $moduleId
        }
        catch {
            Write-LogError "설치 실패: $moduleId - $_"
            $failed += $moduleId
        }
    }
    
    Write-Host ""
    Write-LogSuccess "설치 완료: $($installed.Count)개"
    if ($failed.Count -gt 0) {
        Write-LogWarn "실패: $($failed.Count)개"
    }
}

function Show-MainMenu {
    Show-Banner
    
    Write-Host ""
    Write-LogInfo "설치 옵션을 선택하세요:"
    Write-Host ""
    
    $choice = Show-Menu @(
        "인터랙티브 모듈 선택",
        "프리셋 선택",
        "종료"
    )
    
    return $choice
}

function Show-PresetsMenu {
    $presetsDir = Join-Path $scriptDir "presets"
    
    if (-not (Test-Path $presetsDir)) {
        Write-LogError "프리셋 디렉토리를 찾을 수 없습니다"
        return
    }
    
    $presets = @()
    Get-ChildItem -Path $presetsDir -Filter "*.json" | ForEach-Object {
        $preset = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $presets += @{
            Name = $preset.name
            File = $_.BaseName
            Description = $preset.description
        }
    }
    
    Write-Host ""
    Write-LogInfo "사용 가능한 프리셋:"
    Write-Host ""
    
    for ($i = 0; $i -lt $presets.Count; $i++) {
        Write-Host "$($i+1). $($presets[$i].Name)"
        Write-Host "   $($presets[$i].Description)" -ForegroundColor DarkGray
    }
    
    $selection = Read-Host "프리셋 번호 입력 (1-$($presets.Count))"
    
    if ([int]$selection -ge 1 -and [int]$selection -le $presets.Count) {
        return $presets[$selection - 1].File
    }
    
    return $null
}

function Show-ModulesMenu {
    $allModules = Get-AllModules
    
    if ($allModules.Count -eq 0) {
        Write-LogError "사용 가능한 모듈이 없습니다"
        return $null
    }
    
    # 카테고리 별 그룹화
    $byCategory = $allModules | Group-Object { $_.category } -AsHashTable
    
    Write-Host ""
    Write-LogInfo "설치할 모듈을 선택하세요 (Space로 선택, Enter로 확인):"
    Write-Host ""
    
    $selected = @()
    $currentIndex = 0
    
    foreach ($category in $byCategory.Keys | Sort-Object) {
        Write-LogInfo "▶ $category"
        
        foreach ($module in $byCategory[$category]) {
            $currentIndex++
            Write-Host "$currentIndex. $($module.name)" -ForegroundColor Cyan
            Write-Host "   $($module.description)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    $input = Read-Host "설치할 모듈 번호 입력 (쉼표로 구분, 예: 1,3,5)"
    
    if ($input) {
        $numbers = $input -split ',' | ForEach-Object { [int]$_.Trim() }
        $allModulesList = $allModules | Sort-Object { 
            $_.category + '.' + $_.name 
        }
        
        foreach ($num in $numbers) {
            if ($num -ge 1 -and $num -le $allModulesList.Count) {
                $selected += $allModulesList[$num - 1].id
            }
        }
    }
    
    return $selected
}

function Show-Summary {
    param(
        [array]$ModuleIds,
        [switch]$IsPreset
    )
    
    Write-Host ""
    Write-Section "설치 요약"
    Write-Host ""
    
    Write-LogInfo "설치할 모듈:"
    foreach ($moduleId in $ModuleIds) {
        $meta = Get-ModuleMetadata $moduleId
        if ($meta) {
            Write-Host "  ✓ $($meta.name) ($moduleId)" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    if (Test-DryRunMode) {
        Write-LogWarn "⚠️  DRY RUN 모드 - 실제 설치가 아닌 미리보기입니다"
    }
    
    $confirm = Read-Host "계속 설치하시겠습니까? (y/n)"
    return $confirm -eq 'y'
}

# 메인 로직
try {
    if ($Preset) {
        # 프리셋 모드
        $modules = Get-PresetModules $Preset
        if ($modules) {
            $moduleIds = $modules.id
            if (Show-Summary $moduleIds -IsPreset) {
                Install-Modules $moduleIds
            }
        }
    }
    elseif ($Module) {
        # 직접 모듈 지정
        if (Show-Summary $Module) {
            Install-Modules $Module
        }
    }
    else {
        # 인터랙티브 모드
        $choice = Show-MainMenu
        
        switch ($choice) {
            0 {
                # 인터랙티브 모듈 선택
                $selected = Show-ModulesMenu
                if ($selected -and $selected.Count -gt 0) {
                    if (Show-Summary $selected) {
                        Install-Modules $selected
                    }
                }
            }
            1 {
                # 프리셋 선택
                $preset = Show-PresetsMenu
                if ($preset) {
                    $modules = Get-PresetModules $preset
                    if ($modules) {
                        $moduleIds = $modules.id
                        if (Show-Summary $moduleIds -IsPreset) {
                            Install-Modules $moduleIds
                        }
                    }
                }
            }
            default {
                Write-LogInfo "프로그램을 종료합니다."
            }
        }
    }
    
    Write-Host ""
    Write-LogSuccess "모든 작업이 완료되었습니다!"
}
catch {
    Write-LogError "오류 발생: $_"
    Write-Host $_.Exception.StackTrace
    exit 1
}
