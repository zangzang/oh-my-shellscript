```powershell
# 패키지 캐시 환경 변수 딕셔너리 정의
$packageCacheProfiles = [ordered]@{
    npm = @{
        npm_config_cache = "D:\cache\npm"
        SOURCE_PATH = "$env:APPDATA\npm-cache"
        ALTERNATE_SOURCE_PATH = "$env:LOCALAPPDATA\npm-cache"
    }
    nuget = @{
        NUGET_PACKAGES = "D:\$env:USERNAME\.nuget\packages"
        SOURCE_PATH = "$env:USERPROFILE\.nuget\packages"
    }
    vcpkg = @{
        VCPKG_DEFAULT_BINARY_CACHE = "D:\cache\vcpkg"
        SOURCE_PATH = "$env:LOCALAPPDATA\vcpkg\archives"
        ALTERNATE_SOURCE_PATH = "$env:APPDATA\vcpkg\archives"
    }
    pip = @{
        PIP_CACHE_DIR = "D:\cache\pip"
        SOURCE_PATH = "$env:LOCALAPPDATA\pip\Cache"
    }
    cargo = @{
        CARGO_HOME = "D:\cache\cargo"
        SOURCE_PATH = "$env:USERPROFILE\.cargo"
    }
    maven = @{
        MAVEN_OPTS = "-Dmaven.repo.local=D:\cache\maven"
        SOURCE_PATH = "$env:USERPROFILE\.m2\repository"
    }
    gradle = @{
        GRADLE_USER_HOME = "D:\cache\gradle"
        SOURCE_PATH = "$env:USERPROFILE\.gradle"
    }
    yarn = @{
        YARN_CACHE_FOLDER = "D:\cache\yarn"
        SOURCE_PATH = "$env:LOCALAPPDATA\Yarn\Cache"
        ALTERNATE_SOURCE_PATH = "$env:APPDATA\Yarn\Cache"
    }
}

# 공통: 확장 함수
function Expand-EnvVars {
    param([string]$value)
    try {
        return [System.Environment]::ExpandEnvironmentVariables($value)
    } catch {
        Write-Warning "환경 변수 확장 중 오류 발생: $_"
        return $value
    }
}

function Test-PathExists {
    param([string]$path)
    try {
        $expanded = Expand-EnvVars($path)
        return Test-Path $expanded
    } catch {
        Write-Warning "경로 확인 중 오류 발생: $_"
        return $false
    }
}

function Move-CacheDirectory {
    param(
        [string]$sourcePath,
        [string]$alternateSourcePath = $null,
        [string]$destinationPath
    )
    try {
        $source = if (Test-PathExists $sourcePath) { $sourcePath } elseif ($alternateSourcePath -and (Test-PathExists $alternateSourcePath)) { $alternateSourcePath } else { $null }
        if ($source -and (Test-Path $source)) {
            if (-not (Test-Path $destinationPath)) {
                New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
            }
            Write-Host "📂 기존 캐시를 이동합니다: $source -> $destinationPath"
            Move-Item -Path "$source\*" -Destination $destinationPath -Force -ErrorAction Stop
            Write-Host "✅ 캐시 이동 완료"
        } else {
            Write-Host "ℹ️ 이동할 캐시가 없습니다: $sourcePath"
        }
    } catch {
        Write-Warning "캐시 디렉터리 이동 중 오류 발생: $_"
    }
}

function Apply-PackageCacheDict {
    param(
        [hashtable]$envVars,
        [string]$scope = "User"  # "User", "Machine", or "Process" for current session
    )
    try {
        # 캐시 디렉터리 이동 처리
        if ($envVars.ContainsKey("SOURCE_PATH")) {
            $sourcePath = $envVars["SOURCE_PATH"]
            $alternateSourcePath = $envVars["ALTERNATE_SOURCE_PATH"]
            $destinationPath = $null

            # 대상 경로를 환경 변수 값에서 추출
            foreach ($key in $envVars.Keys) {
                if ($key -notin @("SOURCE_PATH", "ALTERNATE_SOURCE_PATH")) {
                    if ($key -eq "MAVEN_OPTS") {
                        # MAVEN_OPTS에서 -Dmaven.repo.local 값을 추출
                        $mavenRepo = ($envVars[$key] -split "=")[1]
                        $destinationPath = Expand-EnvVars($mavenRepo)
                    } else {
                        $destinationPath = Expand-EnvVars($envVars[$key])
                    }
                    break
                }
            }

            if ($destinationPath) {
                Move-CacheDirectory -sourcePath $sourcePath -alternateSourcePath $alternateSourcePath -destinationPath $destinationPath
            }
        }

        # 환경 변수 설정
        foreach ($key in $envVars.Keys) {
            if ($key -in @("SOURCE_PATH", "ALTERNATE_SOURCE_PATH")) { continue }
            $value = $envVars[$key]
            $expanded = Expand-EnvVars($value)

            # 경로가 존재하는지 확인 (MAVEN_OPTS는 경로가 아닌 옵션이므로 제외)
            if ($key -ne "MAVEN_OPTS" -and -not (Test-PathExists $expanded)) {
                Write-Warning "캐시 경로가 존재하지 않습니다: $key = $expanded"
                New-Item -Path $expanded -ItemType Directory -Force | Out-Null
                Write-Host "📁 새 캐시 디렉터리 생성: $expanded"
            }

            [Environment]::SetEnvironmentVariable($key, $expanded, $scope)
            Write-Host "✅ $key = $expanded"
        }
    } catch {
        Write-Error "환경 변수 적용 중 오류 발생: $_"
    }
}

# 선택 메뉴
Write-Host "`n🛠️ 설정할 패키지 캐시 환경을 선택하세요:"
$index = 1
$packageCacheProfiles.Keys | ForEach-Object {
    Write-Host "$index. $_"
    $index++
}

# 입력 유효성 검사
$choice = Read-Host "번호 입력 (1-$($packageCacheProfiles.Count)) 또는 'q'로 종료"
if ($choice -eq 'q') {
    Write-Host "🚪 종료합니다."
    exit
}

if (-not ($choice -match '^\d+$') -or [int]$choice -lt 1 -or [int]$choice -gt $packageCacheProfiles.Count) {
    Write-Host "❌ 잘못된 입력입니다. 1~$($packageCacheProfiles.Count) 사이의 번호를 입력하세요."
    exit
}

# 키 매칭
$selectedKey = $packageCacheProfiles.Keys[[int]$choice - 1]

# 적용 범위 선택
Write-Host "`n적용 범위를 선택하세요:"
Write-Host "1. 현재 세션 (임시)"
Write-Host "2. 사용자 환경 변수 (영구)"
$scopeChoice = Read-Host "번호 입력 (1-2)"

$scope = if ($scopeChoice -eq "1") { "Process" } else { "User" }

Write-Host "`n🚀 '$selectedKey' 패키지 캐시 환경을 $scope 범위에 적용합니다..."

# 환경 변수 적용 전 확인
Write-Host "`n다음 환경 변수를 적용합니다:"
foreach ($key in $packageCacheProfiles[$selectedKey].Keys) {
    if ($key -notin @("SOURCE_PATH", "ALTERNATE_SOURCE_PATH")) {
        Write-Host "$key = $($packageCacheProfiles[$selectedKey][$key])"
    }
}
$confirm = Read-Host "계속하시겠습니까? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "🚪 적용이 취소되었습니다."
    exit
}

# 환경 변수 적용
Apply-PackageCacheDict $packageCacheProfiles[$selectedKey] -scope $scope
Write-Host "✅ 적용 완료. 새 PowerShell 창을 열어 확인하세요 (영구 변경의 경우)."
```