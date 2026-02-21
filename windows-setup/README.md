# Windows 개발 환경 자동 설치 시스템

Windows 개발 환경을 한방에 세팅하는 모듈식 자동화 도구입니다.
[linux-setup](../linux-setup/) 시스템과 동일한 철학으로 구성되었습니다.

## 🎯 주요 기능

- **모듈식 설계**: 각 도구를 독립적인 모듈로 관리
- **프리셋 지원**: 용도별 사전 정의된 설치 조합
- **Dry Run 모드**: 설치 전에 변경 사항 미리보기
- **의존성 관리**: 자동으로 필요한 도구부터 설치
- **다중 패키지 매니저**: winget, Chocolatey, Scoop 지원

## 📋 시스템 요구사항

- **Windows 11** 이상
- **PowerShell 7.0** 이상
- **관리자 권한** 필요
- **인터넷 연결** (패키지 다운로드용)

## 🚀 빠른 시작

Windows 실행 진입점은 루트의 `omss.ps1` 하나만 사용합니다.

### 1. 인터랙티브 모드 (추천)

```powershell
cd ..
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
.\omss.ps1
```

### 2. 프리셋 사용

```powershell
# .NET 개발자 설정
.\omss.ps1 -Preset dotnet-dev

# 자바 개발자 설정
.\omss.ps1 -Preset java-dev

# 파이썬 개발자 설정
.\omss.ps1 -Preset python-dev

# Node.js 개발자 설정
.\omss.ps1 -Preset node-dev

# Rust 개발자 설정
.\omss.ps1 -Preset rust-dev

# 풀스택 개발자 설정 (모든 도구)
.\omss.ps1 -Preset fullstack-dev
```

### 3. 특정 모듈만 설치

```powershell
# Git, VSCode, Node.js 설치
.\omss.ps1 -Module "dev.git", "dev.vscode", "dev.nodejs"
```

### 4. Dry Run (미리보기)

```powershell
# 실제 설치 없이 설치 계획만 표시
.\omss.ps1 -Preset dotnet-dev -DryRun
```

## 📁 폴더 구조

```
windows-setup/
├── omss/
│   └── windows-setup.py        # 내부 구현 (직접 실행 비권장)
├── ..\omss.ps1                # 메인 진입점 (루트)
├── README.md                  # 이 파일
├── lib/                       # 공유 라이브러리
│   ├── core.psm1             # 핵심 함수 (로깅, 권한 관리)
│   ├── ui.psm1               # UI 컴포넌트 (메뉴, 배너)
│   └── installer.psm1        # 설치 헬퍼 함수
├── modules/                   # 설치 모듈
│   ├── dev/                  # 개발 도구
│   │   ├── git/
│   │   ├── vscode/
│   │   ├── nodejs/
│   │   ├── python/
│   │   ├── java/
│   │   ├── dotnet/
│   │   ├── rust/
│   │   └── docker/
│   ├── gui/                  # GUI 애플리케이션
│   │   ├── chrome/
│   │   ├── notion/
│   │   ├── discord/
│   │   └── dbeaver/
│   ├── tools/                # CLI 유틸리티
│   │   ├── powershell/
│   │   ├── terminal/
│   │   ├── oh-my-posh/
│   │   └── gsudo/
│   └── system/               # 시스템 도구
│       └── winget/
├── presets/                   # 프리셋 정의
│   ├── base.json
│   ├── dotnet-dev.json
│   ├── java-dev.json
│   ├── python-dev.json
│   ├── node-dev.json
│   ├── rust-dev.json
│   └── fullstack-dev.json
└── config/                    # 설정 파일
    └── settings.json
```

## 🛠️ 사용 가능한 모듈

### 개발 도구 (dev/)

| 모듈 ID | 설명 |
|---------|------|
| `dev.git` | Git 버전 관리 |
| `dev.vscode` | Visual Studio Code 에디터 |
| `dev.nodejs` | Node.js 런타임 |
| `dev.python` | Python 인터프리터 |
| `dev.java` | Java Development Kit |
| `dev.dotnet` | .NET SDK |
| `dev.rust` | Rust 프로그래밍 언어 |
| `dev.docker` | Docker Desktop |

### GUI 애플리케이션 (gui/)

| 모듈 ID | 설명 |
|---------|------|
| `gui.chrome` | Google Chrome 브라우저 |
| `gui.notion` | Notion 협업 도구 |
| `gui.discord` | Discord 채팅 |
| `gui.dbeaver` | DBeaver 데이터베이스 관리 |

### 도구 (tools/)

| 모듈 ID | 설명 |
|---------|------|
| `tools.powershell` | PowerShell 7 |
| `tools.terminal` | Windows Terminal |
| `tools.oh-my-posh` | Oh My Posh 터미널 프롬프트 |
| `tools.gsudo` | gsudo (Windows용 sudo) |

### 시스템 (system/)

| 모듈 ID | 설명 |
|---------|------|
| `system.winget` | Windows 패키지 매니저 |

## 📦 사용 가능한 프리셋

### base.json - 기본 설정
필수 도구만 설치합니다.
- Git
- Windows Terminal
- PowerShell 7

### dotnet-dev.json - .NET 개발자
ASP.NET Core, C# 개발 환경입니다.
- Git, VSCode, Node.js, .NET SDK, Docker

### java-dev.json - 자바 개발자
Java 개발 환경입니다.
- Git, VSCode, Java (OpenJDK 17), Docker

### python-dev.json - 파이썬 개발자
Python 개발 환경입니다.
- Git, VSCode, Python, Docker

### node-dev.json - Node.js 개발자
웹 개발 환경입니다.
- Git, VSCode, Node.js, Docker, Chrome

### rust-dev.json - Rust 개발자
Rust 개발 환경입니다.
- Git, VSCode, Rust, Docker

### fullstack-dev.json - 풀스택 개발자
모든 개발 도구를 설치합니다.
- 모든 개발 도구, GUI 애플리케이션, 유틸리티

## 🔧 모듈 구조

각 모듈은 다음 구조를 가집니다:

```
modules/<category>/<name>/
├── meta.json      # 모듈 메타데이터
└── install.ps1   # 설치 스크립트
```

참고: 일반 사용은 `omss.ps1`로만 진행하고, 내부 `windows-setup/omss/windows-setup.py`는 구현 상세로 취급합니다.

### meta.json 예시

```json
{
  "id": "dev.git",
  "name": "Git",
  "category": "dev",
  "description": "분산 버전 관리 시스템",
  "requires": ["system.winget"],
  "installMethod": "winget",
  "wingetId": "Git.Git"
}
```

### install.ps1 예시

```powershell
#!/usr/bin/env pwsh

# 이미 설치되어 있는지 확인
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-LogSuccess "Git 이미 설치됨"
    exit 0
}

# 설치 실행
Write-LogInfo "Git 설치 중..."
Install-WithWinget -Id "Git.Git" -Name "Git" -DryRun:$(Test-DryRunMode)
```

## 📝 명령어 참고

### PowerShell 실행 정책 설정

```powershell
# 현재 사용자 영역에서만 RemoteSigned 허용
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 원래대로 복원
Set-ExecutionPolicy -ExecutionPolicy Default -Scope CurrentUser
```

### 자주 사용하는 명령어

```powershell
# 설치된 프로그램 확인
Get-InstalledProgram "vscode"

# Winget 업데이트
winget upgrade --all

# 특정 도구 버전 확인
git --version
node --version
python --version
dotnet --version
```

## ⚙️ 라이브러리 함수

### core.psm1

**로깅 함수:**
- `Write-LogInfo` - 정보 메시지
- `Write-LogSuccess` - 성공 메시지
- `Write-LogWarn` - 경고 메시지
- `Write-LogError` - 에러 메시지

**권한 함수:**
- `Test-Administrator` - 관리자 권한 확인
- `Assert-Administrator` - 관리자 권한 요구

**패키지 매니저 함수:**
- `Test-Winget` - Winget 설치 확인
- `Test-Chocolatey` - Chocolatey 설치 확인
- `Test-Scoop` - Scoop 설치 확인
- `Get-InstalledProgram` - 설치된 프로그램 확인

### ui.psm1

**UI 함수:**
- `Show-Banner` - 배너 표시
- `Show-Menu` - 메뉴 표시
- `Confirm-Action` - 확인 프롬프트
- `Write-Section` - 섹션 제목 표시

### installer.psm1

**설치 함수:**
- `Install-WithWinget` - Winget으로 설치
- `Install-WithChocolatey` - Chocolatey로 설치
- `Install-WithScoop` - Scoop으로 설치
- `Install-DirectDownload` - 직접 다운로드 및 설치

## 🔒 안전 기능

### Dry Run 모드

`-DryRun` 플래그로 설치 전에 변경 사항을 미리 확인할 수 있습니다.

```powershell
# 미리보기
.\omss.ps1 -Preset fullstack-dev -DryRun

# 실제 설치
.\omss.ps1 -Preset fullstack-dev
```

## 🐛 문제 해결

### PowerShell 보안 정책 오류

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Winget이 설치되지 않음

Windows 11 최신 버전으로 업데이트하거나 Microsoft Store에서 앱 설치관리자를 설치하세요.

## 📚 추가 리소스

- [linux-setup 문서](../linux-setup/README.md)
- [Copilot 지침](.github/copilot-instructions.md)
- [Winget 공식 문서](https://github.com/microsoft/winget-cli)
- [PowerShell 공식 문서](https://learn.microsoft.com/en-us/powershell/)

---

**마지막 업데이트**: 2025년
**버전**: 1.0
