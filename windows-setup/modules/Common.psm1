#Requires -Version 5.1
<#
.SYNOPSIS
    공통 유틸리티 함수 모듈
.DESCRIPTION
    Dev Drive 설정에 사용되는 공통 함수들을 제공합니다.
#>

# ============================================================================
# Dry Run 지원
# ============================================================================

$Script:IsDryRun = $false

function Set-DryRunMode {
    param([bool]$Enabled)
    $Script:IsDryRun = $Enabled
}

function Test-DryRun {
    return $Script:IsDryRun
}

function Write-DryRun {
    <#
    .SYNOPSIS
        Dry Run 모드에서 수행될 작업을 표시합니다.
    #>
    param([string]$Message)
    
    Write-Host "🔍 [DRY RUN] $Message" -ForegroundColor Magenta
}

# ============================================================================
# 환경 변수 처리 함수
# ============================================================================

function Expand-EnvVars {
    <#
    .SYNOPSIS
        환경 변수를 확장합니다.
    #>
    param([string]$Value)
    try {
        return [System.Environment]::ExpandEnvironmentVariables($Value)
    }
    catch {
        Write-Warning "환경 변수 확장 중 오류: $_"
        return $Value
    }
}

function Test-PathExists {
    <#
    .SYNOPSIS
        경로 존재 여부를 확인합니다.
    #>
    param([string]$Path)
    try {
        $expanded = Expand-EnvVars $Path
        return Test-Path $expanded
    }
    catch {
        return $false
    }
}

# ============================================================================
# 권한 확인 함수
# ============================================================================

function Test-Administrator {
    <#
    .SYNOPSIS
        현재 세션이 관리자 권한으로 실행 중인지 확인합니다.
    #>
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    <#
    .SYNOPSIS
        관리자 권한이 필요한 작업 전에 호출합니다.
    #>
    param([string]$Operation = "이 작업")
    
    if (-not (Test-Administrator)) {
        Write-Host ""
        Write-Host "❌ $Operation 은(는) 관리자 권한이 필요합니다." -ForegroundColor Red
        Write-Host "   PowerShell을 '관리자 권한으로 실행'하여 다시 시도하세요." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    return $true
}

# ============================================================================
# Windows 버전 확인
# ============================================================================

function Test-DevDriveSupport {
    <#
    .SYNOPSIS
        Dev Drive 지원 여부를 확인합니다.
        Windows 11 빌드 22621.2338 이상 필요
    #>
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    
    if ($build -lt 22621) {
        Write-Host "❌ Dev Drive는 Windows 11 (빌드 22621) 이상이 필요합니다." -ForegroundColor Red
        Write-Host "   현재 빌드: $build" -ForegroundColor Yellow
        return $false
    }
    
    # UBR (Update Build Revision) 확인
    try {
        $ubr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name UBR).UBR
        if ($build -eq 22621 -and $ubr -lt 2338) {
            Write-Host "⚠️ Dev Drive는 빌드 22621.2338 이상을 권장합니다." -ForegroundColor Yellow
            Write-Host "   현재: 22621.$ubr" -ForegroundColor Yellow
        }
    }
    catch {
        # UBR을 읽을 수 없어도 계속 진행
    }
    
    return $true
}

function Get-WindowsVersionInfo {
    <#
    .SYNOPSIS
        Windows 버전 정보를 반환합니다.
    #>
    $os = Get-CimInstance Win32_OperatingSystem
    $build = $os.BuildNumber
    try {
        $ubr = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name UBR).UBR
        $displayVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
    }
    catch {
        $ubr = "N/A"
        $displayVersion = "N/A"
    }
    
    return @{
        Caption        = $os.Caption
        Version        = $displayVersion
        Build          = $build
        UBR            = $ubr
        FullBuild      = "$build.$ubr"
        DevDriveSupport = ([int]$build -ge 22621)
    }
}

# ============================================================================
# 환경 변수 백업/복원
# ============================================================================

function Backup-EnvironmentVariable {
    <#
    .SYNOPSIS
        환경 변수를 백업합니다.
    #>
    param(
        [string]$Name,
        [string]$Scope = "User",
        [string]$BackupDir = "$env:USERPROFILE\.devdrive-backup"
    )
    
    try {
        if (-not (Test-Path $BackupDir)) {
            New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
        }
        
        $value = [Environment]::GetEnvironmentVariable($Name, $Scope)
        if ($value) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupFile = Join-Path $BackupDir "$Name`_$Scope`_$timestamp.txt"
            $value | Out-File -FilePath $backupFile -Encoding UTF8
            Write-Host "📦 백업됨: $Name -> $backupFile" -ForegroundColor DarkGray
            return $backupFile
        }
    }
    catch {
        Write-Warning "환경 변수 백업 실패: $_"
    }
    return $null
}

function Get-EnvironmentBackups {
    <#
    .SYNOPSIS
        백업된 환경 변수 목록을 반환합니다.
    #>
    param([string]$BackupDir = "$env:USERPROFILE\.devdrive-backup")
    
    if (Test-Path $BackupDir) {
        return Get-ChildItem -Path $BackupDir -Filter "*.txt" | Sort-Object LastWriteTime -Descending
    }
    return @()
}

# ============================================================================
# 안전한 환경 변수 설정
# ============================================================================

function Set-EnvironmentVariableSafe {
    <#
    .SYNOPSIS
        환경 변수를 안전하게 설정합니다 (백업 후 설정).
    .PARAMETER Name
        환경 변수 이름
    .PARAMETER Value
        설정할 값
    .PARAMETER Scope
        범위 (User, Machine, Process)
    .PARAMETER NoBackup
        백업을 건너뜁니다
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Value,
        
        [ValidateSet("User", "Machine", "Process")]
        [string]$Scope = "User",
        
        [switch]$NoBackup
    )
    
    try {
        # Machine 스코프는 관리자 권한 필요
        if ($Scope -eq "Machine" -and -not (Test-Administrator)) {
            Write-Warning "Machine 범위 설정에는 관리자 권한이 필요합니다. User 범위로 변경합니다."
            $Scope = "User"
        }
        
        # 값 확장
        $expandedValue = Expand-EnvVars $Value
        
        # Dry Run 모드
        if (Test-DryRun) {
            Write-DryRun "환경 변수 설정: $Name = $expandedValue [$Scope]"
            return $true
        }
        
        # 기존 값 백업
        if (-not $NoBackup) {
            Backup-EnvironmentVariable -Name $Name -Scope $Scope | Out-Null
        }
        
        # 설정
        [Environment]::SetEnvironmentVariable($Name, $expandedValue, $Scope)
        
        # 현재 세션에도 적용
        if ($Scope -ne "Process") {
            [Environment]::SetEnvironmentVariable($Name, $expandedValue, "Process")
        }
        
        Write-Host "✅ $Name = $expandedValue [$Scope]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "환경 변수 설정 실패: $_"
        return $false
    }
}

function Add-ToPathSafe {
    <#
    .SYNOPSIS
        PATH에 경로를 안전하게 추가합니다.
    .DESCRIPTION
        - 중복 확인
        - 경로 존재 확인
        - 기존 PATH 백업
        - 사용자 PATH만 수정 (Machine PATH는 건드리지 않음)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",
        
        [switch]$Force,
        [switch]$NoBackup
    )
    
    try {
        $expandedPath = Expand-EnvVars $Path
        
        # 경로 존재 확인
        if (-not $Force -and -not (Test-Path $expandedPath)) {
            Write-Warning "경로가 존재하지 않습니다: $expandedPath"
            Write-Host "   -Force 옵션으로 강제 추가 가능" -ForegroundColor DarkGray
            return $false
        }
        
        # 현재 PATH 가져오기
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $Scope)
        $pathArray = $currentPath -split ";" | Where-Object { $_ -ne "" }
        
        # 중복 확인
        $normalizedNew = $expandedPath.TrimEnd('\').ToLower()
        $isDuplicate = $pathArray | Where-Object { $_.TrimEnd('\').ToLower() -eq $normalizedNew }
        
        if ($isDuplicate) {
            Write-Host "ℹ️ PATH에 이미 존재: $expandedPath" -ForegroundColor Cyan
            return $true
        }
        
        # 백업
        if (-not $NoBackup) {
            Backup-EnvironmentVariable -Name "Path" -Scope $Scope | Out-Null
        }
        
        # 추가
        $newPath = ($pathArray + $expandedPath) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, $Scope)
        
        # 현재 세션에도 적용
        $env:Path = "$env:Path;$expandedPath"
        
        Write-Host "➕ PATH 추가됨: $expandedPath [$Scope]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "PATH 추가 실패: $_"
        return $false
    }
}

# ============================================================================
# UI 유틸리티
# ============================================================================

function Show-Banner {
    <#
    .SYNOPSIS
        배너를 표시합니다.
    #>
    param([string]$Title = "Windows Dev Drive Setup")
    
    $width = 60
    $line = "=" * $width
    
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ("  " + $Title).PadRight($width) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    <#
    .SYNOPSIS
        선택 메뉴를 표시합니다.
    #>
    param(
        [string]$Title,
        [string[]]$Options,
        [switch]$MultiSelect,
        [int[]]$DefaultSelections = @()
    )
    
    Write-Host ""
    Write-Host "📋 $Title" -ForegroundColor Yellow
    Write-Host ("-" * 40) -ForegroundColor DarkGray
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $prefix = if ($DefaultSelections -contains ($i + 1)) { "[*]" } else { "[ ]" }
        if (-not $MultiSelect) { $prefix = "   " }
        Write-Host "  $($i + 1). $prefix $($Options[$i])"
    }
    
    Write-Host ""
    if ($MultiSelect) {
        Write-Host "  여러 항목 선택: 1,3,5 또는 1-5 형식" -ForegroundColor DarkGray
    }
    Write-Host "  q: 종료" -ForegroundColor DarkGray
    Write-Host ""
    
    $input = Read-Host "선택"
    
    if ($input -eq 'q' -or $input -eq 'Q') {
        return $null
    }
    
    if ($MultiSelect) {
        $selections = @()
        foreach ($part in ($input -split ",")) {
            $part = $part.Trim()
            if ($part -match "^(\d+)-(\d+)$") {
                $start = [int]$Matches[1]
                $end = [int]$Matches[2]
                $selections += $start..$end
            }
            elseif ($part -match "^\d+$") {
                $selections += [int]$part
            }
        }
        return $selections | Where-Object { $_ -ge 1 -and $_ -le $Options.Count } | Sort-Object -Unique
    }
    else {
        if ($input -match "^\d+$" -and [int]$input -ge 1 -and [int]$input -le $Options.Count) {
            return [int]$input
        }
    }
    
    Write-Host "❌ 잘못된 입력입니다." -ForegroundColor Red
    return -1
}

function Confirm-Action {
    <#
    .SYNOPSIS
        사용자 확인을 요청합니다.
    #>
    param(
        [string]$Message,
        [switch]$DefaultYes
    )
    
    $prompt = if ($DefaultYes) { "(Y/n)" } else { "(y/N)" }
    $response = Read-Host "$Message $prompt"
    
    if ($DefaultYes) {
        return $response -ne 'n' -and $response -ne 'N'
    }
    else {
        return $response -eq 'y' -or $response -eq 'Y'
    }
}

function Write-Step {
    <#
    .SYNOPSIS
        단계별 메시지를 출력합니다.
    #>
    param(
        [int]$Step,
        [int]$Total,
        [string]$Message
    )
    
    Write-Host ""
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Cyan
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

# ============================================================================
# 설정 파일 처리
# ============================================================================

function Get-DevDriveConfig {
    <#
    .SYNOPSIS
        설정 파일을 로드합니다.
    #>
    param(
        [string]$ConfigPath
    )
    
    if (-not $ConfigPath) {
        $ConfigPath = Join-Path $PSScriptRoot "..\config\dev-drive.json"
    }
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "설정 파일을 찾을 수 없습니다: $ConfigPath"
        return $null
    }
    
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Error "설정 파일 파싱 오류: $_"
        return $null
    }
}

# ============================================================================
# Export
# ============================================================================

Export-ModuleMember -Function @(
    'Expand-EnvVars',
    'Test-PathExists',
    'Test-Administrator',
    'Assert-Administrator',
    'Test-DevDriveSupport',
    'Get-WindowsVersionInfo',
    'Backup-EnvironmentVariable',
    'Get-EnvironmentBackups',
    'Set-EnvironmentVariableSafe',
    'Add-ToPathSafe',
    'Show-Banner',
    'Show-Menu',
    'Confirm-Action',
    'Write-Step',
    'Get-DevDriveConfig',
    'Set-DryRunMode',
    'Test-DryRun',
    'Write-DryRun'
)
