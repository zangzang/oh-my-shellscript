#Requires -Version 5.1
<#
.SYNOPSIS
    패키지 캐시 환경 변수 관리 모듈
.DESCRIPTION
    Dev Drive에 패키지 캐시를 설정하고 환경 변수를 관리합니다.
#>

# Common 모듈 로드
$commonModule = Join-Path $PSScriptRoot "Common.psm1"
if (Test-Path $commonModule) {
    Import-Module $commonModule -Force -Global
}

# ============================================================================
# 패키지 캐시 프로필 정의
# ============================================================================

$Script:PackageCacheProfiles = [ordered]@{
    npm = @{
        Name         = "npm (Node.js)"
        EnvVar       = "npm_config_cache"
        TargetPath   = "npm"
        SourcePaths  = @("$env:APPDATA\npm-cache", "$env:LOCALAPPDATA\npm-cache")
        Description  = "Node.js 패키지 매니저 캐시"
    }
    nuget = @{
        Name         = "NuGet (.NET)"
        EnvVar       = "NUGET_PACKAGES"
        TargetPath   = "nuget"
        SourcePaths  = @("$env:USERPROFILE\.nuget\packages")
        Description  = ".NET 패키지 캐시"
    }
    pip = @{
        Name         = "pip (Python)"
        EnvVar       = "PIP_CACHE_DIR"
        TargetPath   = "pip"
        SourcePaths  = @("$env:LOCALAPPDATA\pip\Cache")
        Description  = "Python 패키지 캐시"
    }
    cargo = @{
        Name         = "Cargo (Rust)"
        EnvVar       = "CARGO_HOME"
        TargetPath   = "cargo"
        SourcePaths  = @("$env:USERPROFILE\.cargo")
        Description  = "Rust 패키지 및 도구 캐시"
    }
    maven = @{
        Name         = "Maven (Java)"
        EnvVar       = "MAVEN_OPTS"
        EnvValue     = "-Dmaven.repo.local={path}"
        TargetPath   = "maven"
        SourcePaths  = @("$env:USERPROFILE\.m2\repository")
        Description  = "Maven 로컬 저장소"
    }
    gradle = @{
        Name         = "Gradle (Java)"
        EnvVar       = "GRADLE_USER_HOME"
        TargetPath   = "gradle"
        SourcePaths  = @("$env:USERPROFILE\.gradle")
        Description  = "Gradle 캐시 및 설정"
    }
    vcpkg = @{
        Name         = "vcpkg (C/C++)"
        EnvVar       = "VCPKG_DEFAULT_BINARY_CACHE"
        TargetPath   = "vcpkg"
        SourcePaths  = @("$env:LOCALAPPDATA\vcpkg\archives", "$env:APPDATA\vcpkg\archives")
        Description  = "C/C++ 패키지 매니저 캐시"
    }
    yarn = @{
        Name         = "Yarn"
        EnvVar       = "YARN_CACHE_FOLDER"
        TargetPath   = "yarn"
        SourcePaths  = @("$env:LOCALAPPDATA\Yarn\Cache", "$env:APPDATA\Yarn\Cache")
        Description  = "Yarn 패키지 캐시"
    }
    pnpm = @{
        Name         = "pnpm"
        EnvVar       = "PNPM_HOME"
        TargetPath   = "pnpm"
        SourcePaths  = @("$env:LOCALAPPDATA\pnpm")
        Description  = "pnpm 패키지 캐시"
    }
    go = @{
        Name         = "Go"
        EnvVar       = "GOPATH"
        TargetPath   = "go"
        SourcePaths  = @("$env:USERPROFILE\go")
        Description  = "Go 모듈 캐시"
    }
    composer = @{
        Name         = "Composer (PHP)"
        EnvVar       = "COMPOSER_HOME"
        TargetPath   = "composer"
        SourcePaths  = @("$env:APPDATA\Composer")
        Description  = "PHP Composer 캐시"
    }
}

# ============================================================================
# 캐시 상태 조회
# ============================================================================

function Get-PackageCacheStatus {
    <#
    .SYNOPSIS
        패키지 캐시 환경 변수의 현재 상태를 조회합니다.
    #>
    param(
        [string[]]$Packages = $Script:PackageCacheProfiles.Keys
    )
    
    $results = @()
    
    foreach ($pkg in $Packages) {
        if ($pkg -notin $Script:PackageCacheProfiles.Keys) {
            continue
        }
        
        $profile = $Script:PackageCacheProfiles[$pkg]
        $currentValue = [Environment]::GetEnvironmentVariable($profile.EnvVar, "User")
        
        # Machine 레벨도 확인
        if (-not $currentValue) {
            $currentValue = [Environment]::GetEnvironmentVariable($profile.EnvVar, "Machine")
        }
        
        # 원본 캐시 크기 계산
        $sourceSize = 0
        foreach ($sourcePath in $profile.SourcePaths) {
            $expanded = [Environment]::ExpandEnvironmentVariables($sourcePath)
            if (Test-Path $expanded) {
                $sourceSize += (Get-ChildItem -Path $expanded -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum
            }
        }
        
        $results += [PSCustomObject]@{
            Package       = $pkg
            Name          = $profile.Name
            EnvVar        = $profile.EnvVar
            CurrentValue  = $currentValue
            IsConfigured  = [bool]$currentValue
            SourceSizeMB  = [math]::Round($sourceSize / 1MB, 2)
            Description   = $profile.Description
        }
    }
    
    return $results
}

function Show-PackageCacheStatus {
    <#
    .SYNOPSIS
        패키지 캐시 상태를 표시합니다.
    #>
    $status = Get-PackageCacheStatus
    
    Write-Host ""
    Write-Host "📦 패키지 캐시 환경 변수 상태:" -ForegroundColor Cyan
    Write-Host ("-" * 70) -ForegroundColor DarkGray
    
    foreach ($item in $status) {
        $icon = if ($item.IsConfigured) { "✅" } else { "⬜" }
        $sizeInfo = if ($item.SourceSizeMB -gt 0) { "($($item.SourceSizeMB) MB)" } else { "" }
        
        Write-Host "  $icon $($item.Name.PadRight(20)) " -NoNewline
        
        if ($item.IsConfigured) {
            Write-Host $item.CurrentValue -ForegroundColor Green
        }
        else {
            Write-Host "(미설정) $sizeInfo" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
}

# ============================================================================
# 캐시 디렉토리 이동
# ============================================================================

function Move-PackageCache {
    <#
    .SYNOPSIS
        기존 패키지 캐시를 새 위치로 이동합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Package,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        
        [switch]$Force
    )
    
    if ($Package -notin $Script:PackageCacheProfiles.Keys) {
        Write-Host "❌ 알 수 없는 패키지: $Package" -ForegroundColor Red
        return $false
    }
    
    $profile = $Script:PackageCacheProfiles[$Package]
    
    # 원본 경로 찾기
    $sourcePath = $null
    foreach ($path in $profile.SourcePaths) {
        $expanded = [Environment]::ExpandEnvironmentVariables($path)
        if (Test-Path $expanded) {
            $sourcePath = $expanded
            break
        }
    }
    
    if (-not $sourcePath) {
        Write-Host "ℹ️ 이동할 캐시가 없습니다: $Package" -ForegroundColor DarkGray
        return $true
    }
    
    # Dry Run 모드
    if (Test-DryRun) {
        Write-DryRun "캐시 이동: $sourcePath -> $DestinationPath"
        return $true
    }
    
    # 대상 디렉토리 생성
    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }
    
    # 대상에 이미 파일이 있는지 확인
    $existingItems = Get-ChildItem -Path $DestinationPath -ErrorAction SilentlyContinue
    if ($existingItems -and -not $Force) {
        Write-Host "⚠️ 대상 경로에 이미 파일이 존재합니다: $DestinationPath" -ForegroundColor Yellow
        if (-not (Confirm-Action "기존 파일과 병합하시겠습니까?")) {
            return $false
        }
    }
    
    try {
        Write-Host "📂 캐시 이동 중: $($profile.Name)"
        Write-Host "   원본: $sourcePath"
        Write-Host "   대상: $DestinationPath"
        
        # 파일 이동
        $items = Get-ChildItem -Path $sourcePath -ErrorAction SilentlyContinue
        if ($items) {
            foreach ($item in $items) {
                $destItem = Join-Path $DestinationPath $item.Name
                if (Test-Path $destItem) {
                    if ($Force) {
                        Remove-Item $destItem -Recurse -Force
                    }
                    else {
                        Write-Host "   ⏭️ 건너뜀 (이미 존재): $($item.Name)" -ForegroundColor DarkGray
                        continue
                    }
                }
                Move-Item -Path $item.FullName -Destination $DestinationPath -Force
            }
        }
        
        Write-Host "✅ 캐시 이동 완료" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "캐시 이동 실패: $_"
        return $false
    }
}

# ============================================================================
# 패키지 캐시 환경 변수 설정
# ============================================================================

function Set-PackageCacheEnv {
    <#
    .SYNOPSIS
        패키지 캐시 환경 변수를 설정합니다.
    .PARAMETER Package
        패키지 이름 (npm, nuget, pip 등)
    .PARAMETER BasePath
        Dev Drive 기본 경로 (예: D:\packages)
    .PARAMETER Scope
        환경 변수 범위 (User 권장)
    .PARAMETER MoveExisting
        기존 캐시를 새 위치로 이동
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Package,
        
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",
        
        [switch]$MoveExisting
    )
    
    if ($Package -notin $Script:PackageCacheProfiles.Keys) {
        Write-Host "❌ 알 수 없는 패키지: $Package" -ForegroundColor Red
        Write-Host "   사용 가능: $($Script:PackageCacheProfiles.Keys -join ', ')" -ForegroundColor DarkGray
        return $false
    }
    
    # Machine 스코프 권한 확인
    if ($Scope -eq "Machine" -and -not (Test-Administrator)) {
        Write-Host "⚠️ Machine 범위에는 관리자 권한이 필요합니다. User 범위로 변경합니다." -ForegroundColor Yellow
        $Scope = "User"
    }
    
    $profile = $Script:PackageCacheProfiles[$Package]
    $targetPath = Join-Path $BasePath $profile.TargetPath
    
    # 환경 변수 값 결정
    $envValue = $targetPath
    if ($profile.EnvValue) {
        $envValue = $profile.EnvValue -replace '\{path\}', $targetPath
    }
    
    # Dry Run 모드
    if (Test-DryRun) {
        Write-DryRun "디렉토리 생성: $targetPath"
        Write-DryRun "환경 변수 설정: $($profile.EnvVar) = $envValue [$Scope]"
        return $true
    }
    
    # 대상 디렉토리 생성
    if (-not (Test-Path $targetPath)) {
        Write-Host "📁 디렉토리 생성: $targetPath"
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    
    # 기존 캐시 이동
    if ($MoveExisting) {
        Move-PackageCache -Package $Package -DestinationPath $targetPath
    }
    
    # 환경 변수 설정
    try {
        # 기존 값 백업
        Backup-EnvironmentVariable -Name $profile.EnvVar -Scope $Scope | Out-Null
        
        [Environment]::SetEnvironmentVariable($profile.EnvVar, $envValue, $Scope)
        
        # 현재 세션에도 적용
        [Environment]::SetEnvironmentVariable($profile.EnvVar, $envValue, "Process")
        
        Write-Host "✅ $($profile.EnvVar) = $envValue [$Scope]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "환경 변수 설정 실패: $_"
        return $false
    }
}

function Set-AllPackageCacheEnv {
    <#
    .SYNOPSIS
        여러 패키지 캐시 환경 변수를 한 번에 설정합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Packages,
        
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",
        
        [switch]$MoveExisting
    )
    
    Write-Host ""
    Write-Host "🔧 패키지 캐시 환경 변수 설정" -ForegroundColor Cyan
    Write-Host "   기본 경로: $BasePath"
    Write-Host "   범위: $Scope"
    Write-Host "   패키지: $($Packages -join ', ')"
    Write-Host ""
    
    # 기본 디렉토리 생성
    if (-not (Test-Path $BasePath)) {
        Write-Host "📁 기본 디렉토리 생성: $BasePath"
        New-Item -Path $BasePath -ItemType Directory -Force | Out-Null
    }
    
    $success = 0
    $failed = 0
    
    foreach ($pkg in $Packages) {
        Write-Host ""
        Write-Host "📦 $pkg 설정 중..." -ForegroundColor Yellow
        
        if (Set-PackageCacheEnv -Package $pkg -BasePath $BasePath -Scope $Scope -MoveExisting:$MoveExisting) {
            $success++
        }
        else {
            $failed++
        }
    }
    
    Write-Host ""
    Write-Host ("-" * 50) -ForegroundColor DarkGray
    Write-Host "✅ 완료: $success 성공" -ForegroundColor Green -NoNewline
    if ($failed -gt 0) {
        Write-Host ", $failed 실패" -ForegroundColor Red
    }
    else {
        Write-Host ""
    }
    
    return ($failed -eq 0)
}

# ============================================================================
# 프리셋
# ============================================================================

function Get-PackageCachePresets {
    <#
    .SYNOPSIS
        사용 가능한 프리셋 목록을 반환합니다.
    #>
    return @{
        minimal   = @("npm", "nuget")
        frontend  = @("npm", "yarn", "pnpm")
        dotnet    = @("nuget", "npm")
        java      = @("maven", "gradle", "npm")
        python    = @("pip", "npm")
        rust      = @("cargo", "npm")
        fullstack = @("npm", "nuget", "pip", "cargo", "maven", "gradle")
        all       = $Script:PackageCacheProfiles.Keys
    }
}

function Set-PackageCachePreset {
    <#
    .SYNOPSIS
        프리셋을 사용하여 패키지 캐시를 설정합니다.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Preset,
        
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",
        
        [switch]$MoveExisting
    )
    
    $presets = Get-PackageCachePresets
    
    if ($Preset -notin $presets.Keys) {
        Write-Host "❌ 알 수 없는 프리셋: $Preset" -ForegroundColor Red
        Write-Host "   사용 가능: $($presets.Keys -join ', ')" -ForegroundColor DarkGray
        return $false
    }
    
    $packages = $presets[$Preset]
    return Set-AllPackageCacheEnv -Packages $packages -BasePath $BasePath -Scope $Scope -MoveExisting:$MoveExisting
}

# ============================================================================
# Export
# ============================================================================

Export-ModuleMember -Function @(
    'Get-PackageCacheStatus',
    'Show-PackageCacheStatus',
    'Move-PackageCache',
    'Set-PackageCacheEnv',
    'Set-AllPackageCacheEnv',
    'Get-PackageCachePresets',
    'Set-PackageCachePreset'
) -Variable @(
    'PackageCacheProfiles'
)
