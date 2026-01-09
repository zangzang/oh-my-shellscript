# Linux Setup Assistant (Modular)

Kubuntu 25.04 (Plasma 6 + Wayland) 및 다양한 Linux 환경을 위해 완전히 리팩토링된 모듈식 설정 도구입니다.
기존의 선형적인 쉘 스크립트를 대체하여, **TUI(Text User Interface)** 기반으로 원하는 모듈만 선택하거나 프리셋을 통해 원클릭 셋업을 지원합니다.

## ✨ 주요 기능

*   **🖥️ 대화형 TUI**: `gum`을 활용한 직관적인 메뉴, 체크박스 선택, 애니메이션 지원.
*   **🧩 완전 모듈화**: 모든 설치 항목이 `modules/{category}/{name}` 단위로 분리되어 관리하기 쉽습니다.
*   **📦 의존성 자동 해결**: `meta.json`에 정의된 의존성(`requires`)을 자동으로 추적하여 필요한 모듈을 함께 설치합니다.
*   **📄 프리셋 지원**: `base`, `java-dev` 등 미리 정의된 구성으로 빠르게 환경을 구축할 수 있습니다.
*   **🔍 Dry Run (시뮬레이션)**: 실제 설치 전에 어떤 스크립트가 실행될지 미리 확인해볼 수 있습니다.
*   **↩️ 자유로운 탐색**: 상태 머신(State Machine) 구조로 메뉴 간 이동(뒤로 가기)이 자유롭습니다.
*   **🔐 자동 권한 수정**: 압축 해제 후에도 실행 권한이 자동으로 복구됩니다.

## 🚀 사용법

### 0. 압축 해제 후 권한 처리

프로젝트를 압축해서 이동한 경우 실행 권한이 손실될 수 있습니다.  
`easy-setup.sh`가 실행 시 자동으로 모든 `install.sh` 파일의 권한을 수정하므로, 별도 작업이 필요하지 않습니다.

```bash
# easy-setup.sh가 자동으로 권한을 수정합니다
bash easy-setup.sh
```

### 1. 기본 실행 (대화형 모드)

가장 권장되는 방식입니다. TUI 메뉴를 통해 프리셋을 고르거나 직접 설치할 모듈을 선택할 수 있습니다.

```bash
chmod +x easy-setup.sh
./easy-setup.sh
```

**[실행 단계]**
1.  **모드 선택**: 프리셋 목록 또는 `직접 선택(Custom Selection)` 중 선택.
2.  **모듈 선택** (Custom 모드 시): 설치하고 싶은 항목을 `Space`로 체크.
3.  **최종 확인**: 의존성이 해결된 최종 설치 목록 확인 (체크 해제하여 제외 가능).
4.  **실행 선택**:
    *   `🚀 설치 진행`: 실제 설치 시작.
    *   `🔍 시뮬레이션`: Dry Run 로그 출력.

### 🔍 Dry Run (시뮬레이션) 절차

실제로 시스템을 변경하기 전에 수행될 작업을 미리 확인할 수 있습니다.

1.  **목록 검토 완료**: `REVIEW LIST` 화면에서 설치할 항목들을 최종 확인합니다.
2.  **작업 선택**: 확인 후 `Enter`를 누르면 작업 선택 메뉴가 나타납니다.
3.  **시뮬레이션 선택**: `🔍 시뮬레이션 (Dry Run)`을 선택합니다.
4.  **결과 확인**:
    *   터미널에 `[Dry Run]` 태그와 함께 실행될 내용이 출력됩니다.
    *   설치될 **모듈명**, **Variant(버전)**, **실행될 스크립트 경로**를 확인할 수 있습니다.
    *   *실제 파일 변경이나 설치 명령은 실행되지 않습니다.*

### 2. 프리셋 바로 실행 (One-shot)

특정 프리셋을 인자로 주어 바로 의존성 확인 화면으로 넘어갑니다.

```bash
./easy-setup.sh java-dev
# 또는
./easy-setup.sh presets/base.json
```

## 📂 프로젝트 구조

```
linux-setup/
├── easy-setup.sh       # 메인 실행 스크립트 (TUI)
├── lib/                # 공통 함수 라이브러리 (로깅, 권한 체크 등)
├── modules/            # 설치 모듈 디렉토리
│   ├── system/         # 시스템 설정 (update, essentials 등)
│   ├── dev/            # 개발 도구 (docker, java, node, python 등)
│   └── gui/            # GUI 애플리케이션 (vscode, chrome 등)
├── presets/            # 설치 프리셋 JSON 파일
├── docs/               # 추가 가이드 문서
└── legacy/             # (참고용) 이전 버전의 스크립트 백업
```

## 📚 추가 가이드 문서

- **[REMOTE_SETUP_GUIDE.md](docs/REMOTE_SETUP_GUIDE.md)** - SSH 원격 서버 설정 및 자동화
  - NOPASSWD 설정으로 sudo 비밀번호 없이 자동화
  - SSH를 통한 원격 명령 실행 패턴
  - 완전 자동화 워크플로우 예시
  
- **[PERMISSIONS.md](docs/PERMISSIONS.md)** - 로컬 권한 관리 및 압축 처리
  - 실행 권한 문제 해결
  - tar/zip 권한 유지 방법
  
- **[JAVA_GUIDE.md](docs/JAVA_GUIDE.md)** - Java 개발 환경 설정
  
- **[VSCODE_EXTENSIONS_GUIDE.md](docs/VSCODE_EXTENSIONS_GUIDE.md)** - VSCode 확장 프로그램 구성

## 🛠️ 모듈 추가 방법

새로운 소프트웨어나 설정을 추가하려면 `modules/` 아래에 디렉토리를 만들고 두 파일을 생성하세요.

**1. meta.json**
```json
{
  "id": "my-tool",
  "name": "My Custom Tool",
  "category": "tools",
  "description": "Install my custom tool",
  "requires": ["git", "curl"]
}
```

**2. install.sh**
```bash
#!/bin/bash
# 첫 번째 인자로 variant(버전 등)가 전달됩니다.
VERSION=${1:-"default"}

echo "Installing My Tool ($VERSION)..."
# 설치 로직 작성
```

## 📋 프리셋 커스터마이징

프리셋 파일(`presets/*.json`)에서 모듈의 기본 선택 상태를 제어할 수 있습니다.

**기본 선택 제어 (`params.selected`)**
```json
{
  "name": "My Preset",
  "modules": [
    { "id": "dev.java", "params": { "version": "21" } },
    { "id": "gui.vscode" },
    { "id": "gui.sts", "params": { "selected": false } }
  ]
}
```

- `"selected": false`: 목록에 표시되지만 기본적으로 선택되지 않음 (옵션 항목)
- `"selected": true` 또는 생략: 기본적으로 선택됨
- 사용자는 리뷰 화면에서 자유롭게 선택/해제할 수 있습니다

## ⚠️ 요구 사항 및 도구 설치

### 원칙: 이 프로젝트의 모듈 우선 사용

**새로운 도구가 필요할 때는 다음 순서를 따르세요:**

1. **`modules/` 디렉토리 확인**: 이미 설치 모듈이 있는지 확인
   ```bash
   # 예: Node.js, Python, Java, Rust 등은 modules/dev/ 또는 modules/tools/에 있습니다
   ls -la modules/*/
   ```

2. **있으면 `easy-setup.sh` 사용** (apt 직접 사용 금지):
   ```bash
   ./easy-setup.sh --preset <preset-name> --execute
   # 또는
   ./easy-setup.sh --preset base --vscode-extras <tool> --execute
   ```

3. **없으면 모듈 추가**:
   - `modules/{category}/{tool-name}/install.sh` 생성
   - `modules/{category}/{tool-name}/meta.json` 작성
   - 프리셋에 포함시키거나 CLI로 사용 가능하게 구성

### 필수 기본 도구

이 스크립트는 내부적으로 `gum`, `jq`를 사용합니다. `easy-setup.sh` 실행 시 초기에 자동으로 확인하고 없으면 설치를 시도합니다.

### 예시: 새로운 도구 필요 시

```bash
# ❌ 하지 마세요
apt install nodejs

# ✅ 이렇게 하세요
./easy-setup.sh --preset node-dev --execute

# 모듈이 없다면 다음 구조로 추가:
# modules/dev/your-tool/install.sh
# modules/dev/your-tool/meta.json
```
