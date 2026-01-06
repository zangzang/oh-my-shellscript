# 환경 변수 딕셔너리 정의 (확장 버전)
$envProfiles = [ordered]@{
    java = @{
        JAVA_HOME = "D:\devtools\jdk-17"
        PATH_ADD = "%JAVA_HOME%\bin"
    }
    java8 = @{
        JAVA_HOME = "D:\devtools\jdk-8"
        PATH_ADD = "%JAVA_HOME%\bin"
    }
    maven = @{
        MAVEN_HOME = "D:\devtools\maven-3.9.9"
        PATH_ADD = "%MAVEN_HOME%\bin"
    }
    gradle = @{
        GRADLE_HOME = "D:\devtools\gradle-8.7"
        PATH_ADD = "%GRADLE_HOME%\bin"
    }
    flutter = @{
        FLUTTER_HOME = "D:\devtools\flutter"
        PATH_ADD = "%FLUTTER_HOME%\bin"
    }
    android = @{
        ANDROID_HOME = "D:\devtools\Android\Sdk"
        PATH_ADD = "%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\cmdline-tools\latest\bin"
    }
    nodejs = @{
        NODEJS_HOME = "D:\devtools\nodejs"
        PATH_ADD = "%NODEJS_HOME%"
    }
    python = @{
        PYTHON_HOME = "D:\devtools\Python310"
        PATH_ADD = "%PYTHON_HOME%;%PYTHON_HOME%\Scripts"
    }
    dotnet = @{
        DOTNET_ROOT = "D:\devtools\dotnet"
        PATH_ADD = "%DOTNET_ROOT%"
    }
    rust = @{
        CARGO_HOME = "D:\Users\jangjongwoo\.cargo"
        RUSTUP_HOME = "D:\Users\jangjongwoo\.rustup"
        PATH_ADD = "%CARGO_HOME%\bin"
    }
    go = @{
        GOROOT = "D:\devtools\go"
        GOPATH = "D:\Users\jangjongwoo\go"
        PATH_ADD = "%GOROOT%\bin;%GOPATH%\bin"
    }
    ruby = @{
        RUBY_HOME = "D:\devtools\ruby-3.2.2"
        PATH_ADD = "%RUBY_HOME%\bin"
    }
    php = @{
        PHP_HOME = "D:\devtools\php-8.2"
        PATH_ADD = "%PHP_HOME%"
    }
    git = @{
        GIT_HOME = "C:\Program Files\Git"
        PATH_ADD = "%GIT_HOME%\cmd;%GIT_HOME%\bin"
    }
    terraform = @{
        TERRAFORM_HOME = "D:\devtools\terraform"
        PATH_ADD = "%TERRAFORM_HOME%"
    }
    kubectl = @{
        KUBECTL_HOME = "D:\devtools\kubectl"
        PATH_ADD = "%KUBECTL_HOME%"
    }
    vscode = @{
        VSCODE_HOME = "C:\Program Files\Microsoft VS Code"
        PATH_ADD = "%VSCODE_HOME%"
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

function Apply-EnvDict {
    param(
        [hashtable]$envVars,
        [string]$scope = "User"  # "User", "Machine", or "Process" for current session
    )

    try {
        foreach ($key in $envVars.Keys) {
            $value = $envVars[$key]

            if ($key -ieq "PATH_ADD") {
                $expandedPaths = (Expand-EnvVars($value) -split ";") | Where-Object { $_ }
                $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope) -split ";" | Where-Object { $_ }

                foreach ($path in $expandedPaths) {
                    if (-not (Test-PathExists $path)) {
                        Write-Warning "경로가 존재하지 않습니다: $path"
                        continue
                    }
                    if ($currentPath -notcontains $path) {
                        $currentPath += $path
                        Write-Host "➕ PATH 추가됨: $path"
                    } else {
                        Write-Host "ℹ️ PATH 이미 존재: $path"
                    }
                }
                [Environment]::SetEnvironmentVariable("Path", ($currentPath -join ";"), $scope)
            } else {
                if (-not (Test-PathExists $value)) {
                    Write-Warning "환경 변수 경로가 존재하지 않습니다: $key = $value"
                    continue
                }
                $expanded = Expand-EnvVars($value)
                [Environment]::SetEnvironmentVariable($key, $expanded, $scope)
                Write-Host "✅ $key = $expanded"
            }
        }
    } catch {
        Write-Error "환경 변수 적용 중 오류 발생: $_"
    }
}

# 선택 메뉴
Write-Host "`n🛠️ 설정할 개발 환경을 선택하세요:"
$index = 1
$envProfiles.Keys | ForEach-Object {
    Write-Host "$index. $_"
    $index++
}

# 입력 유효성 검사
$choice = Read-Host "번호 입력 (1-$($envProfiles.Count)) 또는 'q'로 종료"
if ($choice -eq 'q') {
    Write-Host "🚪 종료합니다."
    exit
}

if (-not ($choice -match '^\d+$') -or [int]$choice -lt 1 -or [int]$choice -gt $envProfiles.Count) {
    Write-Host "❌ 잘못된 입력입니다. 1~$($envProfiles.Count) 사이의 번호를 입력하세요."
    exit
}

# 키 매칭
$selectedKey = $envProfiles.Keys[[int]$choice - 1]

# 적용 범위 선택
Write-Host "`n적용 범위를 선택하세요:"
Write-Host "1. 현재 세션 (임시)"
Write-Host "2. 사용자 환경 변수 (영구)"
$scopeChoice = Read-Host "번호 입력 (1-2)"

$scope = if ($scopeChoice -eq "1") { "Process" } else { "User" }

Write-Host "`n🚀 '$selectedKey' 환경을 $scope 범위에 적용합니다..."

# 환경 변수 적용 전 확인
Write-Host "`n다음 환경 변수를 적용합니다:"
foreach ($key in $envProfiles[$selectedKey].Keys) {
    Write-Host "$key = $($envProfiles[$selectedKey][$key])"
}
$confirm = Read-Host "계속하시겠습니까? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "🚪 적용이 취소되었습니다."
    exit
}

# 환경 변수 적용
Apply-EnvDict $envProfiles[$selectedKey] -scope $scope
Write-Host "✅ 적용 완료. 새 PowerShell 창을 열어 확인하세요 (영구 변경의 경우)."
```