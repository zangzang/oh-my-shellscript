#Requires -Version 5.1
<#
.SYNOPSIS
    Dev Drive 관리 모듈
.DESCRIPTION
    Windows 11 Dev Drive 생성, 조회, 신뢰 설정 등을 관리합니다.
#>

# Common 모듈 로드
$commonModule = Join-Path $PSScriptRoot "Common.psm1"
if (Test-Path $commonModule) {
    Import-Module $commonModule -Force -Global
}

# ============================================================================
# Dev Drive 조회
# ============================================================================

function Get-DevDrives {
    <#
    .SYNOPSIS
        시스템의 모든 Dev Drive를 조회합니다.
    #>
    try {
        $volumes = Get-Volume | Where-Object { $_.FileSystem -eq "ReFS" }
        $devDrives = @()
        
        foreach ($vol in $volumes) {
            if ($vol.DriveLetter) {
                $letter = $vol.DriveLetter
                $query = & fsutil devdrv query "${letter}:" 2>&1
                
                if ($query -match "Developer Volume" -or $query -match "개발자 볼륨") {
                    $isTrusted = $query -match "trusted|신뢰"
                    
                    $devDrives += [PSCustomObject]@{
                        DriveLetter = $letter
                        Label       = $vol.FileSystemLabel
                        Size        = [math]::Round($vol.Size / 1GB, 2)
                        FreeSpace   = [math]::Round($vol.SizeRemaining / 1GB, 2)
                        IsTrusted   = $isTrusted
                        FileSystem  = $vol.FileSystem
                    }
                }
            }
        }
        
        return $devDrives
    }
    catch {
        Write-Warning "Dev Drive 조회 실패: $_"
        return @()
    }
}

function Show-DevDriveStatus {
    <#
    .SYNOPSIS
        Dev Drive 상태를 표시합니다.
    #>
    $devDrives = Get-DevDrives
    
    if ($devDrives.Count -eq 0) {
        Write-Host ""
        Write-Host "ℹ️ 현재 시스템에 Dev Drive가 없습니다." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-Host "🔍 현재 Dev Drive 목록:" -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    
    foreach ($drive in $devDrives) {
        $trustIcon = if ($drive.IsTrusted) { "✅" } else { "⚠️" }
        $trustText = if ($drive.IsTrusted) { "신뢰됨" } else { "신뢰되지 않음" }
        
        Write-Host "  📁 $($drive.DriveLetter): [$($drive.Label)]" -ForegroundColor White
        Write-Host "     크기: $($drive.Size) GB (여유: $($drive.FreeSpace) GB)"
        Write-Host "     상태: $trustIcon $trustText"
        Write-Host ""
    }
}

# ============================================================================
# Dev Drive 생성 (VHD)
# ============================================================================

function New-DevDriveVHD {
    <#
    .SYNOPSIS
        VHD를 생성하고 Dev Drive로 포맷합니다.
    .PARAMETER Path
        VHD 파일 경로 (예: C:\DevDrives\DevDrive.vhdx)
    .PARAMETER SizeGB
        VHD 크기 (GB)
    .PARAMETER DriveLetter
        마운트할 드라이브 문자
    .PARAMETER Label
        볼륨 레이블
    .PARAMETER Dynamic
        동적 확장 VHD (기본값: true)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [int]$SizeGB,
        
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [string]$Label = "DevDrive",
        
        [switch]$Dynamic = $true
    )
    
    # 관리자 권한 확인
    if (-not (Test-DryRun) -and -not (Assert-Administrator "Dev Drive VHD 생성")) {
        return $false
    }
    
    # 최소 크기 확인
    if ($SizeGB -lt 50) {
        Write-Host "❌ Dev Drive 최소 크기는 50GB입니다." -ForegroundColor Red
        return $false
    }
    
    # Dry Run 모드
    if (Test-DryRun) {
        Write-Host ""
        Write-DryRun "VHD 생성 예정:"
        Write-DryRun "  경로: $Path"
        Write-DryRun "  크기: $SizeGB GB"
        Write-DryRun "  유형: $(if ($Dynamic) { '동적 확장' } else { '고정 크기' })"
        Write-DryRun "  드라이브 문자: ${DriveLetter}:"
        Write-DryRun "  레이블: $Label"
        Write-DryRun "실행될 명령:"
        Write-DryRun "  1. diskpart로 VHD 생성 및 마운트"
        Write-DryRun "  2. Format-Volume -DriveLetter $DriveLetter -DevDrive"
        Write-DryRun "  3. fsutil devdrv trust ${DriveLetter}:"
        Write-Host ""
        return $true
    }
    
    # 드라이브 문자 사용 가능 여부 확인
    $existingVolume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
    if ($existingVolume) {
        Write-Host "❌ 드라이브 문자 $DriveLetter 는 이미 사용 중입니다." -ForegroundColor Red
        return $false
    }
    
    # VHD 경로 디렉토리 확인
    $vhdDir = Split-Path $Path -Parent
    if (-not (Test-Path $vhdDir)) {
        Write-Host "📁 VHD 디렉토리 생성: $vhdDir"
        New-Item -Path $vhdDir -ItemType Directory -Force | Out-Null
    }
    
    # 기존 VHD 파일 확인
    if (Test-Path $Path) {
        Write-Host "⚠️ VHD 파일이 이미 존재합니다: $Path" -ForegroundColor Yellow
        if (-not (Confirm-Action "기존 파일을 사용하여 마운트하시겠습니까?")) {
            return $false
        }
        
        # 기존 VHD 마운트 시도
        return Mount-DevDriveVHD -Path $Path -DriveLetter $DriveLetter
    }
    
    try {
        Write-Host ""
        Write-Host "🔧 VHD 생성 중..." -ForegroundColor Cyan
        Write-Host "   경로: $Path"
        Write-Host "   크기: $SizeGB GB"
        Write-Host "   유형: $(if ($Dynamic) { '동적 확장' } else { '고정 크기' })"
        Write-Host ""
        
        # DiskPart 스크립트 생성
        $sizeBytes = $SizeGB * 1024  # MB 단위
        $vhdType = if ($Dynamic) { "expandable" } else { "fixed" }
        
        $diskpartScript = @"
create vdisk file="$Path" maximum=$sizeBytes type=$vhdType
select vdisk file="$Path"
attach vdisk
create partition primary
format fs=refs quick label="$Label"
assign letter=$DriveLetter
"@
        
        $scriptPath = [System.IO.Path]::GetTempFileName()
        $diskpartScript | Out-File -FilePath $scriptPath -Encoding ASCII
        
        Write-Host "⏳ DiskPart 실행 중..."
        $result = & diskpart /s $scriptPath 2>&1
        
        Remove-Item $scriptPath -Force
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ VHD 생성 실패" -ForegroundColor Red
            Write-Host $result -ForegroundColor Red
            return $false
        }
        
        Write-Host "✅ VHD 생성 완료: ${DriveLetter}:" -ForegroundColor Green
        
        # Dev Drive로 포맷
        Write-Host ""
        Write-Host "🔧 Dev Drive로 포맷 중..."
        
        # Format-Volume -DevDrive 사용
        Format-Volume -DriveLetter $DriveLetter -DevDrive -Confirm:$false | Out-Null
        
        Write-Host "✅ Dev Drive 포맷 완료" -ForegroundColor Green
        
        # 신뢰 설정
        Write-Host ""
        Write-Host "🔧 Dev Drive 신뢰 설정 중..."
        & fsutil devdrv trust "${DriveLetter}:"
        
        Write-Host "✅ Dev Drive 설정 완료!" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "VHD 생성 중 오류: $_"
        return $false
    }
}

function Mount-DevDriveVHD {
    <#
    .SYNOPSIS
        기존 VHD를 마운트합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [char]$DriveLetter
    )
    
    if (-not (Assert-Administrator "VHD 마운트")) {
        return $false
    }
    
    if (-not (Test-Path $Path)) {
        Write-Host "❌ VHD 파일을 찾을 수 없습니다: $Path" -ForegroundColor Red
        return $false
    }
    
    try {
        Write-Host "🔧 VHD 마운트 중: $Path"
        
        Mount-VHD -Path $Path -ErrorAction Stop
        
        # 드라이브 문자 할당이 필요한 경우
        if ($DriveLetter) {
            $disk = Get-VHD -Path $Path
            $partition = Get-Partition -DiskNumber $disk.DiskNumber | Where-Object { $_.Type -eq "Basic" }
            
            if ($partition -and -not $partition.DriveLetter) {
                Set-Partition -InputObject $partition -NewDriveLetter $DriveLetter
            }
        }
        
        Write-Host "✅ VHD 마운트 완료" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "VHD 마운트 실패: $_"
        return $false
    }
}

# ============================================================================
# 기존 볼륨을 Dev Drive로 포맷
# ============================================================================

function ConvertTo-DevDrive {
    <#
    .SYNOPSIS
        기존 볼륨을 Dev Drive로 포맷합니다.
    .DESCRIPTION
        주의: 이 작업은 해당 볼륨의 모든 데이터를 삭제합니다!
    #>
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [string]$Label = "DevDrive"
    )
    
    if (-not (Assert-Administrator "Dev Drive 포맷")) {
        return $false
    }
    
    # 볼륨 확인
    $volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
    if (-not $volume) {
        Write-Host "❌ 드라이브 ${DriveLetter}: 를 찾을 수 없습니다." -ForegroundColor Red
        return $false
    }
    
    # C: 드라이브 확인
    if ($DriveLetter -eq 'C') {
        Write-Host "❌ C: 드라이브는 Dev Drive로 변환할 수 없습니다." -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    Write-Host "⚠️  경고: 이 작업은 ${DriveLetter}: 드라이브의 모든 데이터를 삭제합니다!" -ForegroundColor Red
    Write-Host "   볼륨: $($volume.FileSystemLabel)"
    Write-Host "   크기: $([math]::Round($volume.Size / 1GB, 2)) GB"
    Write-Host ""
    
    if (-not (Confirm-Action "정말로 계속하시겠습니까?")) {
        Write-Host "❌ 작업이 취소되었습니다." -ForegroundColor Yellow
        return $false
    }
    
    # 한 번 더 확인
    $confirmText = Read-Host "확인을 위해 드라이브 문자를 입력하세요 ($DriveLetter)"
    if ($confirmText -ne $DriveLetter) {
        Write-Host "❌ 확인 실패. 작업이 취소되었습니다." -ForegroundColor Yellow
        return $false
    }
    
    try {
        Write-Host ""
        Write-Host "🔧 Dev Drive로 포맷 중..."
        
        # Format-Volume -DevDrive 사용
        Format-Volume -DriveLetter $DriveLetter -FileSystem ReFS -NewFileSystemLabel $Label -DevDrive -Confirm:$false
        
        Write-Host "✅ Dev Drive 포맷 완료" -ForegroundColor Green
        
        # 신뢰 설정
        Write-Host "🔧 신뢰 설정 중..."
        & fsutil devdrv trust "${DriveLetter}:"
        
        Write-Host "✅ Dev Drive 설정 완료!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Dev Drive 포맷 실패: $_"
        return $false
    }
}

# ============================================================================
# 신뢰 설정
# ============================================================================

function Set-DevDriveTrust {
    <#
    .SYNOPSIS
        Dev Drive의 신뢰 상태를 설정합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [switch]$Untrust
    )
    
    if (-not (Assert-Administrator "Dev Drive 신뢰 설정")) {
        return $false
    }
    
    try {
        if ($Untrust) {
            Write-Host "🔧 Dev Drive 신뢰 해제 중..."
            & fsutil devdrv untrust "${DriveLetter}:"
        }
        else {
            Write-Host "🔧 Dev Drive 신뢰 설정 중..."
            & fsutil devdrv trust "${DriveLetter}:"
        }
        
        Write-Host "✅ 완료" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "신뢰 설정 실패: $_"
        return $false
    }
}

function Get-DevDriveInfo {
    <#
    .SYNOPSIS
        특정 Dev Drive의 상세 정보를 조회합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter
    )
    
    try {
        $query = & fsutil devdrv query "${DriveLetter}:" 2>&1
        Write-Host ""
        Write-Host "📊 Dev Drive 정보: ${DriveLetter}:" -ForegroundColor Cyan
        Write-Host ("-" * 50) -ForegroundColor DarkGray
        Write-Host $query
        Write-Host ""
    }
    catch {
        Write-Warning "정보 조회 실패: $_"
    }
}

# ============================================================================
# Export
# ============================================================================

Export-ModuleMember -Function @(
    'Get-DevDrives',
    'Show-DevDriveStatus',
    'New-DevDriveVHD',
    'Mount-DevDriveVHD',
    'ConvertTo-DevDrive',
    'Set-DevDriveTrust',
    'Get-DevDriveInfo'
)
