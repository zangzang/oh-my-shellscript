#Requires -Version 5.1
<#
.SYNOPSIS
    Dev Drive 필터 관리 모듈
.DESCRIPTION
    Dev Drive에 연결할 파일 시스템 필터를 관리합니다.
#>

# Common 모듈 로드
$commonModule = Join-Path $PSScriptRoot "Common.psm1"
if (Test-Path $commonModule) {
    Import-Module $commonModule -Force -Global
}

# ============================================================================
# 필터 정의
# ============================================================================

$Script:FilterDefinitions = @{
    PrjFlt     = "Windows Projected File System (GVFS, sparse enlistment)"
    MsSecFlt   = "Microsoft Defender for Endpoint EDR sensor"
    WdFilter   = "Windows Defender filter (기본 연결됨)"
    bindFlt    = "Docker 컨테이너 지원"
    wcifs      = "Docker 컨테이너 지원"
    FileInfo   = "Windows Performance Recorder, Resource Monitor"
    ProcMon24  = "Process Monitor (Sysinternals)"
    WinSetupMon = "Windows 업그레이드 (TEMP가 Dev Drive인 경우)"
    AppLockerFltr = "Windows Defender Application Control"
}

$Script:FilterPresets = @{
    default = @("WdFilter")
    docker  = @("WdFilter", "bindFlt", "wcifs")
    monitoring = @("WdFilter", "FileInfo", "ProcMon24")
    vscode  = @("WdFilter", "PrjFlt")
    full    = @("WdFilter", "PrjFlt", "MsSecFlt", "bindFlt", "wcifs", "FileInfo")
}

# ============================================================================
# 필터 조회
# ============================================================================

function Get-DevDriveFilters {
    <#
    .SYNOPSIS
        현재 Dev Drive 필터 설정을 조회합니다.
    #>
    param(
        [char]$DriveLetter
    )
    
    try {
        if ($DriveLetter) {
            $query = & fsutil devdrv query "${DriveLetter}:" 2>&1
        }
        else {
            $query = & fsutil devdrv query 2>&1
        }
        
        return $query
    }
    catch {
        Write-Warning "필터 조회 실패: $_"
        return $null
    }
}

function Show-DevDriveFilterStatus {
    <#
    .SYNOPSIS
        Dev Drive 필터 상태를 표시합니다.
    #>
    param(
        [char]$DriveLetter
    )
    
    Write-Host ""
    Write-Host "🔍 Dev Drive 필터 상태" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    $query = Get-DevDriveFilters -DriveLetter $DriveLetter
    
    if ($query) {
        Write-Host $query
    }
    else {
        Write-Host "정보를 가져올 수 없습니다." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📋 사용 가능한 필터:" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    foreach ($filter in $Script:FilterDefinitions.GetEnumerator()) {
        Write-Host "  $($filter.Key.PadRight(15)) - $($filter.Value)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
}

# ============================================================================
# 필터 설정
# ============================================================================

function Set-DevDriveFilters {
    <#
    .SYNOPSIS
        Dev Drive에 허용할 필터를 설정합니다.
    .DESCRIPTION
        이 설정은 시스템의 모든 Dev Drive에 적용됩니다.
    .PARAMETER Filters
        허용할 필터 목록
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Filters
    )
    
    if (-not (Test-DryRun) -and -not (Assert-Administrator "Dev Drive 필터 설정")) {
        return $false
    }
    
    $filterList = $Filters -join ", "
    
    # Dry Run 모드
    if (Test-DryRun) {
        Write-Host ""
        Write-DryRun "필터 설정 예정:"
        Write-DryRun "  허용할 필터: $filterList"
        Write-DryRun "실행될 명령:"
        Write-DryRun "  fsutil devdrv setfiltersallowed $filterList"
        Write-Host ""
        return $true
    }
    
    try {
        Write-Host ""
        Write-Host "🔧 Dev Drive 필터 설정" -ForegroundColor Cyan
        Write-Host "   허용할 필터: $filterList"
        Write-Host ""
        
        # fsutil devdrv setfiltersallowed 실행
        $result = & fsutil devdrv setfiltersallowed $filterList 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 필터 설정 완료" -ForegroundColor Green
            Write-Host $result
            return $true
        }
        else {
            Write-Host "❌ 필터 설정 실패" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Error "필터 설정 중 오류: $_"
        return $false
    }
}

function Set-DevDriveFilterPreset {
    <#
    .SYNOPSIS
        프리셋을 사용하여 필터를 설정합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("default", "docker", "monitoring", "vscode", "full")]
        [string]$Preset
    )
    
    $filters = $Script:FilterPresets[$Preset]
    
    Write-Host ""
    Write-Host "📦 필터 프리셋: $Preset"
    Write-Host "   포함 필터: $($filters -join ', ')"
    
    return Set-DevDriveFilters -Filters $filters
}

function Enable-DevDriveAntivirus {
    <#
    .SYNOPSIS
        Dev Drive에서 바이러스 백신 필터를 활성화합니다.
    #>
    if (-not (Assert-Administrator "바이러스 백신 설정")) {
        return $false
    }
    
    try {
        Write-Host "🔧 Dev Drive 바이러스 백신 필터 활성화..."
        & fsutil devdrv enable /allowAv
        
        Write-Host "✅ 바이러스 백신 필터 활성화됨" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "설정 실패: $_"
        return $false
    }
}

function Disable-DevDriveAntivirus {
    <#
    .SYNOPSIS
        Dev Drive에서 바이러스 백신 필터를 비활성화합니다.
    .DESCRIPTION
        ⚠️ 주의: 이 옵션은 보안 위험이 있습니다.
    #>
    if (-not (Assert-Administrator "바이러스 백신 설정")) {
        return $false
    }
    
    Write-Host ""
    Write-Host "⚠️  경고: 바이러스 백신 필터를 비활성화하면 보안 위험이 증가합니다!" -ForegroundColor Red
    Write-Host "   Dev Drive의 파일이 실시간 검사되지 않습니다." -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Confirm-Action "정말로 비활성화하시겠습니까?")) {
        Write-Host "❌ 작업이 취소되었습니다." -ForegroundColor Yellow
        return $false
    }
    
    try {
        Write-Host "🔧 Dev Drive 바이러스 백신 필터 비활성화..."
        & fsutil devdrv enable /disallowAv
        
        Write-Host "⚠️ 바이러스 백신 필터 비활성화됨" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Error "설정 실패: $_"
        return $false
    }
}

# ============================================================================
# Export
# ============================================================================

Export-ModuleMember -Function @(
    'Get-DevDriveFilters',
    'Show-DevDriveFilterStatus',
    'Set-DevDriveFilters',
    'Set-DevDriveFilterPreset',
    'Enable-DevDriveAntivirus',
    'Disable-DevDriveAntivirus'
) -Variable @(
    'FilterDefinitions',
    'FilterPresets'
)
