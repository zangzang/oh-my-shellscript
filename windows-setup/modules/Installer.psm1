#Requires -Version 5.1
<#
.SYNOPSIS
    설치 헬퍼 함수 모듈
.DESCRIPTION
    Winget 등을 사용한 설치 함수들을 제공합니다.
#>

# ============================================================================
# Winget 관련 함수
# ============================================================================

function Test-Winget {
    <#
    .SYNOPSIS
        Winget 설치 여부를 확인합니다.
    #>
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

function Install-WithWinget {
    <#
    .SYNOPSIS
        Winget을 사용하여 프로그램을 설치합니다.
    .PARAMETER Id
        Winget 패키지 ID
    .PARAMETER Name
        프로그램 이름 (로깅용)
    .PARAMETER DryRun
        Dry Run 여부
    #>
    param(
        [string]$Id,
        [string]$Name,
        [bool]$DryRun = $false
    )
    
    if (-not $Name) { $Name = $Id }
    
    if ($DryRun) {
        Write-LogInfo "[DryRun] Winget 설치: $Name (ID: $Id)"
        return
    }
    
    if (-not (Test-Winget)) {
        Write-LogError "Winget이 설치되어 있지 않습니다."
        throw "Winget not found"
    }
    
    Write-LogInfo "$Name 설치 중... (ID: $Id)"
    
    try {
        # 이미 설치되어 있는지 확인 (간단한 체크)
        $list = winget list --id $Id --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and $list) {
            Write-LogSuccess "$Name 이미 설치되어 있습니다."
            return
        }
        
        # 설치 실행
        winget install --id $Id --accept-package-agreements --accept-source-agreements --silent
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "$Name 설치 완료"
        } else {
            throw "Winget exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-LogError "$Name 설치 실패: $_"
        throw
    }
}

function Get-InstalledProgram {
    <#
    .SYNOPSIS
        설치된 프로그램을 확인합니다.
    #>
    param([string]$Name)
    
    return Get-Command $Name -ErrorAction SilentlyContinue
}

function Install-PowerShellModule {
    <#
    .SYNOPSIS
        PowerShell 모듈을 설치합니다.
    #>
    param(
        [string]$Name,
        [bool]$DryRun = $false
    )
    
    if ($DryRun) {
        Write-LogInfo "[DryRun] PowerShell 모듈 설치: $Name"
        return
    }
    
    if (Get-Module -ListAvailable -Name $Name) {
        Write-LogSuccess "$Name 모듈 이미 설치됨"
        return
    }
    
    Write-LogInfo "$Name 모듈 설치 중..."
    Install-Module -Name $Name -Force -AllowClobber -Scope CurrentUser
}

# ============================================================================
# Export
# ============================================================================

Export-ModuleMember -Function @(
    'Test-Winget',
    'Install-WithWinget',
    'Get-InstalledProgram',
    'Install-PowerShellModule'
)
