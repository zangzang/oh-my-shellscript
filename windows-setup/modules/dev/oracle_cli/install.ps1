#Requires -Version 5.1
<#
.SYNOPSIS
    Oracle InstantClient 설치
.DESCRIPTION
    다운로드 → 압축 해제 → 설치 위치로 이동 → PATH 추가
#>

param(
    [string]$Variant = "23.6",
    [switch]$DryRun
)

# 메타데이터 로드
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metaFile = Join-Path $scriptDir "meta.json"
$meta = Get-Content $metaFile -Raw | ConvertFrom-Json

# settings.json에서 기본 경로 로드
$settingsFile = Join-Path $scriptDir "..\..\..\config\settings.json"
$settings = @{}
if (Test-Path $settingsFile) {
    $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json
}

# 메타의 category로 기본 경로 조회
$category = $meta.category
$basePath = $settings.installPaths.$category
if (-not $basePath) {
    $basePath = "C:\Dev\Tools"
}

# app_folder_name으로 최종 설치 경로 생성
$appFolderName = $meta.app_folder_name
if (-not $appFolderName) {
    $appFolderName = ($meta.id -split "\.")[-1]
}
$installPath = Join-Path $basePath $appFolderName
$tempDir = $env:TEMP
$variantData = $meta.variants.$Variant

if (-not $variantData) {
    Write-Host "❌ 지원하지 않는 버전: $Variant" -ForegroundColor Red
    Write-Host "지원 버전: $($meta.variants.PSObject.Properties.Name -join ', ')" -ForegroundColor Yellow
    exit 1
}

# Basic 및 SQL*Plus 패키지 URL
$basicUrl = $variantData.basic_url
$sqlplusUrl = $variantData.sqlplus_url

$basicFileName = Split-Path -Leaf $basicUrl
$sqlplusFileName = Split-Path -Leaf $sqlplusUrl

$basicDownloadPath = Join-Path $tempDir $basicFileName
$sqlplusDownloadPath = Join-Path $tempDir $sqlplusFileName

function Write-Info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-DryRun($msg) { Write-Host "🔍 [DRY RUN] $msg" -ForegroundColor Magenta }

# DRY RUN Mode
if ($DryRun) {
    Write-DryRun "Oracle InstantClient Version $Variant Download"
    Write-DryRun "   [Basic] $basicUrl"
    Write-DryRun "   -> $basicDownloadPath"
    Write-DryRun "   [SQL*Plus] $sqlplusUrl"
    Write-DryRun "   -> $sqlplusDownloadPath"
    Write-DryRun "Extract: Basic + SQL*Plus -> $tempDir"
    Write-DryRun "Install to: $installPath"
    Write-DryRun "Add to PATH: $installPath"
    Write-DryRun "Set ORACLE_HOME: $installPath"
    exit 0
}

try {
    # 1. Basic 패키지 다운로드
    Write-Info "Oracle InstantClient Basic 다운로드 중..."
    Write-Host "   버전: $Variant" -ForegroundColor Gray
    
    if (Test-Path $basicDownloadPath) {
        Write-Warn "이미 다운로드된 Basic 파일 사용"
    } else {
        try {
            Invoke-WebRequest -Uri $basicUrl -OutFile $basicDownloadPath -ErrorAction Stop
            Write-Success "Basic 다운로드 완료"
        }
        catch {
            Write-Error "Basic 다운로드 실패: $_"
            Write-Host ""
            Write-Warn "Oracle 파일 다운로드는 로그인이 필요할 수 있습니다:"
            Write-Host "   1. https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html" -ForegroundColor Gray
            Write-Host "   2. 회원 계정으로 로그인 후 다운로드" -ForegroundColor Gray
            Write-Host "   3. Basic: $basicDownloadPath 에 저장" -ForegroundColor Gray
            Write-Host "   4. SQL*Plus: $sqlplusDownloadPath 에 저장" -ForegroundColor Gray
            exit 1
        }
    }

    # 2. SQL*Plus 패키지 다운로드
    Write-Info "Oracle SQL*Plus 다운로드 중..."
    
    if (Test-Path $sqlplusDownloadPath) {
        Write-Warn "이미 다운로드된 SQL*Plus 파일 사용"
    } else {
        try {
            Invoke-WebRequest -Uri $sqlplusUrl -OutFile $sqlplusDownloadPath -ErrorAction Stop
            Write-Success "SQL*Plus 다운로드 완료"
        }
        catch {
            Write-Error "SQL*Plus 다운로드 실패: $_"
            Write-Host ""
            Write-Warn "Oracle 파일 다운로드는 로그인이 필요할 수 있습니다:"
            Write-Host "   1. https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html" -ForegroundColor Gray
            Write-Host "   2. 회원 계정으로 로그인 후 다운로드" -ForegroundColor Gray
            Write-Host "   3. SQL*Plus: $sqlplusDownloadPath 에 저장" -ForegroundColor Gray
            exit 1
        }
    }
    
    # 3. 압축 해제 (Basic + SQL*Plus를 같은 폴더에)
    Write-Info "압축 해제 중..."
    $extractDir = Join-Path $tempDir "instantclient_extract_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    
    # Basic 압축 해제
    Write-Host "   Basic 패키지 해제 중..." -ForegroundColor Gray
    Expand-Archive -Path $basicDownloadPath -DestinationPath $extractDir -Force
    Write-Success "Basic 압축 해제 완료"
    
    # SQL*Plus 압축 해제 (같은 폴더에 병합)
    Write-Host "   SQL*Plus 패키지 해제 중..." -ForegroundColor Gray
    Expand-Archive -Path $sqlplusDownloadPath -DestinationPath $extractDir -Force
    Write-Success "SQL*Plus 압축 해제 완료 (Basic과 병합됨)"
    
    # 추출된 InstantClient 디렉토리 찾기
    $instantClientDir = Get-ChildItem $extractDir -Filter "instantclient*" -Directory | Select-Object -First 1
    if (-not $instantClientDir) {
        Write-Error "압축 해제된 InstantClient 디렉토리를 찾을 수 없습니다"
        exit 1
    }
    
    # 4. 설치 경로 준비
    Write-Info "설치 경로 준비 중..."
    if (Test-Path $installPath) {
        Remove-Item $installPath -Recurse -Force
        Write-Warn "기존 설치 제거됨"
    }
    
    New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Write-Success "설치 경로 생성: $installPath"
    
    # 5. 파일 복사
    Write-Info "파일 복사 중..."
    Get-ChildItem $instantClientDir.FullName | Copy-Item -Destination $installPath -Recurse -Force
    Write-Success "파일 복사 완료 (Basic + SQL*Plus 통합)"
    
    # 6. PATH 추가
    Write-Info "PATH 환경 변수 추가 중..."
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathArray = $currentPath -split ";" | Where-Object { $_ -ne "" -and $_ -ne $installPath }
    
    if ($pathArray -notcontains $installPath) {
        $newPath = @($installPath) + $pathArray
        $newPath = $newPath -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Success "PATH 추가 완료"
    } else {
        Write-Warn "이미 PATH에 등록되어 있습니다"
    }
    
    # 7. ORACLE_HOME 설정
    Write-Info "ORACLE_HOME 환경 변수 설정 중..."
    [Environment]::SetEnvironmentVariable("ORACLE_HOME", $installPath, "User")
    Write-Success "ORACLE_HOME 설정: $installPath"
    
    # 8. 검증
    Write-Info "설치 검증 중..."
    $sqlplus = Join-Path $installPath "sqlplus.exe"
    $oci = Join-Path $installPath "oci.dll"
    
    if (Test-Path $sqlplus) {
        Write-Success "SQL*Plus 확인됨: $sqlplus"
    } else {
        Write-Warn "SQL*Plus를 찾을 수 없습니다"
    }
    
    if (Test-Path $oci) {
        Write-Success "OCI 라이브러리 확인됨: $oci"
    } else {
        Write-Warn "OCI 라이브러리를 찾을 수 없습니다"
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Success "Oracle InstantClient 설치 완료!"
    Write-Host "═══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "설치 경로: $installPath" -ForegroundColor Cyan
    Write-Host "ORACLE_HOME: $installPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 테스트 방법:" -ForegroundColor Yellow
    Write-Host "   새 터미널을 열고 'sqlplus /nolog' 실행" -ForegroundColor Gray
    Write-Host ""
    
    # 클린업
    if (Test-Path $extractDir) {
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Error "설치 중 오류 발생: $_"
    exit 1
}
