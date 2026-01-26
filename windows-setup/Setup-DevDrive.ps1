#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Dev Drive 설정 자동화 스크립트
.DESCRIPTION
    Windows 11 개발자 드라이브를 설정하고 패키지 캐시 환경 변수를 구성합니다.
    
    주요 기능:
    - Dev Drive VHD 생성 또는 기존 볼륨 포맷
    - 패키지 캐시 환경 변수 설정 (npm, nuget, pip, cargo, maven, gradle 등)
    - 필터 허용 목록 관리
    - 기존 캐시 마이그레이션

.PARAMETER Mode
    실행 모드
    - Interactive: 대화형 메뉴 (기본값)
    - CacheOnly: 패키지 캐시만 설정
    - DriveOnly: Dev Drive만 생성
    - StatusOnly: 현재 상태만 표시

.PARAMETER Preset
    패키지 캐시 프리셋 (minimal, frontend, dotnet, java, python, rust, fullstack, all)

.PARAMETER DriveLetter
    Dev Drive 드라이브 문자

.PARAMETER BasePath
    패키지 캐시 기본 경로

.EXAMPLE
    .\Setup-DevDrive.ps1
    대화형 모드로 실행

.EXAMPLE
    .\Setup-DevDrive.ps1 -Mode CacheOnly -Preset fullstack -BasePath "D:\packages"
    풀스택 프리셋으로 패키지 캐시만 설정

.EXAMPLE
    .\Setup-DevDrive.ps1 -Mode StatusOnly
    현재 상태만 표시

.NOTES
    Author: DevDrive Setup Script
    Version: 1.0.0
    Requires: Windows 11 Build 22621+
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet("Interactive", "CacheOnly", "DriveOnly", "StatusOnly")]
    [string]$Mode = "Interactive",
    
    [ValidateSet("minimal", "frontend", "dotnet", "java", "python", "rust", "fullstack", "all")]
    [string]$Preset,
    
    [char]$DriveLetter,
    
    [string]$BasePath,
    
    [switch]$MoveExisting,
    
    [switch]$DryRun,
    
    [switch]$Help
)

# DryRun 플래그
$Script:IsDryRun = $DryRun -or $WhatIfPreference

# ============================================================================
# 초기화
# ============================================================================

$ErrorActionPreference = "Stop"

# 스크립트 루트 경로 결정
if ($PSScriptRoot) {
    $ScriptRoot = $PSScriptRoot
} else {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

# 모듈 로드
$modulesPath = Join-Path $ScriptRoot "modules"

# 모듈 경로 확인
if (-not (Test-Path $modulesPath)) {
    Write-Error "모듈 폴더를 찾을 수 없습니다: $modulesPath"
    exit 1
}

Import-Module (Join-Path $modulesPath "Common.psm1") -Force -Global -DisableNameChecking
Import-Module (Join-Path $modulesPath "DevDrive.psm1") -Force -Global -DisableNameChecking
Import-Module (Join-Path $modulesPath "PackageCache.psm1") -Force -Global -DisableNameChecking
Import-Module (Join-Path $modulesPath "Filters.psm1") -Force -Global -DisableNameChecking

# Dry Run 모드 설정 (모듈 로드 후)
if ($Script:IsDryRun) {
    Set-DryRunMode -Enabled $true
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  🔍 DRY RUN 모드 - 실제 변경 없이 시뮬레이션만 수행합니다" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
}

# ============================================================================
# 도움말
# ============================================================================

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# ============================================================================
# 상태 표시
# ============================================================================

function Show-SystemStatus {
    Write-Host ""
    Write-Host "🖥️ 시스템 정보" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    $winInfo = Get-WindowsVersionInfo
    Write-Host "  Windows: $($winInfo.Caption)"
    Write-Host "  버전: $($winInfo.Version) (빌드 $($winInfo.FullBuild))"
    
    $devDriveSupport = if ($winInfo.DevDriveSupport) { "✅ 지원됨" } else { "❌ 미지원" }
    Write-Host "  Dev Drive: $devDriveSupport"
    
    $isAdmin = if (Test-Administrator) { "✅ 관리자" } else { "⚠️ 일반 사용자" }
    Write-Host "  권한: $isAdmin"
    
    Write-Host ""
    
    # Dev Drive 상태
    Show-DevDriveStatus
    
    # 패키지 캐시 상태
    Show-PackageCacheStatus
}

# ============================================================================
# 대화형 메뉴
# ============================================================================

function Show-MainMenu {
    Show-Banner -Title "🚀 Windows Dev Drive Setup"
    
    Write-Host "  Windows 11 개발자 드라이브를 설정하고"
    Write-Host "  패키지 캐시 환경 변수를 구성합니다."
    Write-Host ""
    
    $options = @(
        "📊 현재 상태 확인",
        "💾 Dev Drive 생성/설정",
        "📦 패키지 캐시 환경 변수 설정",
        "🔧 필터 설정",
        "⚡ 빠른 설정 (프리셋 사용)",
        "🔙 환경 변수 백업 확인"
    )
    
    return Show-Menu -Title "메인 메뉴" -Options $options
}

function Invoke-StatusCheck {
    Show-SystemStatus
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

function Invoke-DevDriveSetup {
    Show-Banner -Title "💾 Dev Drive 설정"
    
    # Windows 버전 확인
    if (-not (Test-DevDriveSupport)) {
        Read-Host "계속하려면 Enter를 누르세요"
        return
    }
    
    # 관리자 권한 확인
    if (-not (Test-Administrator)) {
        Write-Host ""
        Write-Host "⚠️ Dev Drive 생성에는 관리자 권한이 필요합니다." -ForegroundColor Yellow
        Write-Host "   PowerShell을 '관리자 권한으로 실행'하세요." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "계속하려면 Enter를 누르세요"
        return
    }
    
    $options = @(
        "새 VHD 생성 (권장)",
        "기존 볼륨을 Dev Drive로 포맷 ⚠️",
        "기존 VHD 마운트",
        "Dev Drive 신뢰 설정/해제",
        "🔙 메인 메뉴로"
    )
    
    $choice = Show-Menu -Title "Dev Drive 설정" -Options $options
    
    switch ($choice) {
        1 {
            # VHD 생성
            Write-Host ""
            $vhdPath = Read-Host "VHD 파일 경로 (기본: C:\DevDrives\DevDrive.vhdx)"
            if (-not $vhdPath) { $vhdPath = "C:\DevDrives\DevDrive.vhdx" }
            
            $sizeInput = Read-Host "VHD 크기 GB (기본: 100, 최소: 50)"
            $sizeGB = if ($sizeInput) { [int]$sizeInput } else { 100 }
            
            $letterInput = Read-Host "드라이브 문자 (기본: D)"
            $letter = if ($letterInput) { $letterInput[0] } else { 'D' }
            
            $label = Read-Host "볼륨 레이블 (기본: DevDrive)"
            if (-not $label) { $label = "DevDrive" }
            
            Write-Host ""
            if (Confirm-Action "VHD를 생성하시겠습니까?") {
                New-DevDriveVHD -Path $vhdPath -SizeGB $sizeGB -DriveLetter $letter -Label $label
            }
        }
        2 {
            # 기존 볼륨 포맷
            Write-Host ""
            Write-Host "⚠️ 경고: 선택한 볼륨의 모든 데이터가 삭제됩니다!" -ForegroundColor Red
            Write-Host ""
            
            # 사용 가능한 볼륨 표시
            Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveLetter -ne 'C' } | 
                Format-Table DriveLetter, FileSystemLabel, FileSystem, @{N='Size(GB)';E={[math]::Round($_.Size/1GB,2)}}
            
            $letterInput = Read-Host "포맷할 드라이브 문자"
            if ($letterInput) {
                ConvertTo-DevDrive -DriveLetter $letterInput[0]
            }
        }
        3 {
            # 기존 VHD 마운트
            Write-Host ""
            $vhdPath = Read-Host "VHD 파일 경로"
            if ($vhdPath -and (Test-Path $vhdPath)) {
                $letterInput = Read-Host "할당할 드라이브 문자 (선택사항)"
                $letter = if ($letterInput) { $letterInput[0] } else { $null }
                Mount-DevDriveVHD -Path $vhdPath -DriveLetter $letter
            }
            else {
                Write-Host "❌ 파일을 찾을 수 없습니다." -ForegroundColor Red
            }
        }
        4 {
            # 신뢰 설정
            $devDrives = Get-DevDrives
            if ($devDrives.Count -eq 0) {
                Write-Host "ℹ️ Dev Drive가 없습니다." -ForegroundColor Yellow
            }
            else {
                Write-Host ""
                Write-Host "현재 Dev Drive:"
                foreach ($d in $devDrives) {
                    $status = if ($d.IsTrusted) { "신뢰됨" } else { "신뢰되지 않음" }
                    Write-Host "  $($d.DriveLetter): - $status"
                }
                
                $letterInput = Read-Host "설정할 드라이브 문자"
                if ($letterInput) {
                    $action = Read-Host "1: 신뢰 설정, 2: 신뢰 해제"
                    if ($action -eq "1") {
                        Set-DevDriveTrust -DriveLetter $letterInput[0]
                    }
                    elseif ($action -eq "2") {
                        Set-DevDriveTrust -DriveLetter $letterInput[0] -Untrust
                    }
                }
            }
        }
        5 {
            return
        }
    }
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

function Invoke-PackageCacheSetup {
    Show-Banner -Title "📦 패키지 캐시 환경 변수 설정"
    
    Write-Host "  패키지 매니저 캐시를 Dev Drive로 설정합니다."
    Write-Host "  환경 변수는 '사용자' 범위에 설정됩니다 (안전)."
    Write-Host ""
    
    # 현재 상태 표시
    Show-PackageCacheStatus
    
    $options = @(
        "개별 패키지 선택",
        "프리셋 사용",
        "모든 패키지 설정",
        "🔙 메인 메뉴로"
    )
    
    $choice = Show-Menu -Title "설정 방식" -Options $options
    
    if ($choice -eq 4 -or $null -eq $choice) {
        return
    }
    
    # 기본 경로 입력
    Write-Host ""
    $basePath = Read-Host "패키지 캐시 기본 경로 (기본: D:\packages)"
    if (-not $basePath) { $basePath = "D:\packages" }
    
    # 기존 캐시 이동 여부
    $moveExisting = Confirm-Action "기존 캐시를 새 위치로 이동하시겠습니까?" -DefaultYes
    
    switch ($choice) {
        1 {
            # 개별 패키지 선택
            $packages = $Script:PackageCacheProfiles.Keys
            $selected = Show-Menu -Title "설정할 패키지 선택" -Options $packages -MultiSelect
            
            if ($selected) {
                $selectedPackages = @()
                foreach ($idx in $selected) {
                    $selectedPackages += $packages[$idx - 1]
                }
                
                Write-Host ""
                Write-Host "선택된 패키지: $($selectedPackages -join ', ')"
                
                if (Confirm-Action "계속하시겠습니까?") {
                    Set-AllPackageCacheEnv -Packages $selectedPackages -BasePath $basePath -Scope "User" -MoveExisting:$moveExisting
                }
            }
        }
        2 {
            # 프리셋 사용
            $presets = Get-PackageCachePresets
            $presetOptions = $presets.Keys | ForEach-Object { "$_ ($($presets[$_] -join ', '))" }
            
            $selected = Show-Menu -Title "프리셋 선택" -Options $presetOptions
            
            if ($selected) {
                $presetName = ($presets.Keys)[$selected - 1]
                
                if (Confirm-Action "$presetName 프리셋을 적용하시겠습니까?") {
                    Set-PackageCachePreset -Preset $presetName -BasePath $basePath -Scope "User" -MoveExisting:$moveExisting
                }
            }
        }
        3 {
            # 모든 패키지
            if (Confirm-Action "모든 패키지 캐시를 설정하시겠습니까?") {
                Set-PackageCachePreset -Preset "all" -BasePath $basePath -Scope "User" -MoveExisting:$moveExisting
            }
        }
    }
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

function Invoke-FilterSetup {
    Show-Banner -Title "🔧 Dev Drive 필터 설정"
    
    # 관리자 권한 확인
    if (-not (Test-Administrator)) {
        Write-Host "⚠️ 필터 설정에는 관리자 권한이 필요합니다." -ForegroundColor Yellow
        Read-Host "계속하려면 Enter를 누르세요"
        return
    }
    
    # 현재 상태 표시
    Show-DevDriveFilterStatus
    
    $options = @(
        "필터 프리셋 적용",
        "개별 필터 설정",
        "바이러스 백신 필터 활성화",
        "바이러스 백신 필터 비활성화 ⚠️",
        "🔙 메인 메뉴로"
    )
    
    $choice = Show-Menu -Title "필터 설정" -Options $options
    
    switch ($choice) {
        1 {
            $presetOptions = @("default", "docker", "monitoring", "vscode", "full")
            $selected = Show-Menu -Title "필터 프리셋" -Options $presetOptions
            
            if ($selected) {
                Set-DevDriveFilterPreset -Preset $presetOptions[$selected - 1]
            }
        }
        2 {
            Write-Host ""
            Write-Host "허용할 필터를 쉼표로 구분하여 입력하세요."
            Write-Host "예: WdFilter, PrjFlt, bindFlt"
            Write-Host ""
            
            $filterInput = Read-Host "필터"
            if ($filterInput) {
                $filters = $filterInput -split "," | ForEach-Object { $_.Trim() }
                Set-DevDriveFilters -Filters $filters
            }
        }
        3 {
            Enable-DevDriveAntivirus
        }
        4 {
            Disable-DevDriveAntivirus
        }
    }
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

function Invoke-QuickSetup {
    Show-Banner -Title "⚡ 빠른 설정"
    
    Write-Host "  자주 사용하는 설정을 빠르게 적용합니다."
    Write-Host ""
    
    $options = @(
        "🎯 풀스택 개발 (npm, nuget, pip, cargo, maven, gradle)",
        "🌐 프론트엔드 개발 (npm, yarn, pnpm)",
        "💜 .NET 개발 (nuget, npm)",
        "☕ Java 개발 (maven, gradle, npm)",
        "🐍 Python 개발 (pip, npm)",
        "🦀 Rust 개발 (cargo, npm)",
        "📦 최소 설정 (npm, nuget)",
        "🔙 메인 메뉴로"
    )
    
    $presetMap = @{
        1 = "fullstack"
        2 = "frontend"
        3 = "dotnet"
        4 = "java"
        5 = "python"
        6 = "rust"
        7 = "minimal"
    }
    
    $choice = Show-Menu -Title "프리셋 선택" -Options $options
    
    if ($choice -eq 8 -or $null -eq $choice -or -not $presetMap.ContainsKey($choice)) {
        return
    }
    
    $preset = $presetMap[$choice]
    
    Write-Host ""
    $basePath = Read-Host "패키지 캐시 기본 경로 (기본: D:\packages)"
    if (-not $basePath) { $basePath = "D:\packages" }
    
    $moveExisting = Confirm-Action "기존 캐시를 새 위치로 이동하시겠습니까?" -DefaultYes
    
    if (Confirm-Action "$preset 프리셋을 적용하시겠습니까?") {
        Set-PackageCachePreset -Preset $preset -BasePath $basePath -Scope "User" -MoveExisting:$moveExisting
    }
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

function Invoke-BackupCheck {
    Show-Banner -Title "🔙 환경 변수 백업"
    
    $backups = Get-EnvironmentBackups
    
    if ($backups.Count -eq 0) {
        Write-Host "ℹ️ 저장된 백업이 없습니다." -ForegroundColor Yellow
    }
    else {
        Write-Host "📦 저장된 백업 목록:" -ForegroundColor Cyan
        Write-Host ("-" * 60) -ForegroundColor DarkGray
        
        foreach ($backup in $backups | Select-Object -First 20) {
            Write-Host "  $($backup.Name) - $($backup.LastWriteTime)"
        }
        
        if ($backups.Count -gt 20) {
            Write-Host "  ... 외 $($backups.Count - 20)개"
        }
        
        Write-Host ""
        Write-Host "백업 위치: $env:USERPROFILE\.devdrive-backup" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    Read-Host "계속하려면 Enter를 누르세요"
}

# ============================================================================
# 비대화형 모드 실행
# ============================================================================

function Invoke-NonInteractiveMode {
    switch ($Mode) {
        "StatusOnly" {
            Show-SystemStatus
        }
        "CacheOnly" {
            if (-not $BasePath) {
                $BasePath = "D:\packages"
            }
            
            if ($Preset) {
                Set-PackageCachePreset -Preset $Preset -BasePath $BasePath -Scope "User" -MoveExisting:$MoveExisting
            }
            else {
                Write-Host "❌ -Preset 파라미터가 필요합니다." -ForegroundColor Red
                Write-Host "   사용 가능: minimal, frontend, dotnet, java, python, rust, fullstack, all"
            }
        }
        "DriveOnly" {
            if (-not $DriveLetter) {
                Write-Host "❌ -DriveLetter 파라미터가 필요합니다." -ForegroundColor Red
                return
            }
            
            Write-Host "Dev Drive 생성은 대화형 모드를 사용하세요: .\Setup-DevDrive.ps1"
        }
    }
}

# ============================================================================
# 메인 루프
# ============================================================================

function Start-InteractiveMode {
    while ($true) {
        Clear-Host
        $choice = Show-MainMenu
        
        switch ($choice) {
            1 { Invoke-StatusCheck }
            2 { Invoke-DevDriveSetup }
            3 { Invoke-PackageCacheSetup }
            4 { Invoke-FilterSetup }
            5 { Invoke-QuickSetup }
            6 { Invoke-BackupCheck }
            $null {
                Write-Host ""
                Write-Host "👋 Setup-DevDrive를 종료합니다." -ForegroundColor Cyan
                Write-Host ""
                exit 0
            }
            default {
                # 잘못된 입력, 메뉴 다시 표시
            }
        }
    }
}

# ============================================================================
# 시작
# ============================================================================

if ($Mode -eq "Interactive") {
    Start-InteractiveMode
}
else {
    Invoke-NonInteractiveMode
}
