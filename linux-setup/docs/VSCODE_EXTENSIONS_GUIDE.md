# VSCode 확장 자동 설치 가이드

VSCode를 설치할 때 개발자 유형별 확장을 자동으로 설치할 수 있습니다.
한 명의 개발자가 여러 언어(Java + .NET 등)를 다루는 경우 필요한 확장을 선택적으로 조합할 수 있습니다.

## 📋 사용 가능한 확장 그룹

| 그룹 | 설명 | 포함된 확장 예 |
|------|------|--------------|
| **base** | 모든 개발자 필수 (자동 포함) | Git, Docker, YAML, Prettier, ESLint, Todo Tree |
| **java** | Java 개발 | Red Hat Java, Maven, Spring Boot, Gradle |
| **dotnet** | C#/.NET 개발 | C# Dev Kit, .NET Runtime, SQL Tools |
| **node** | Node.js/JavaScript 개발 | Node.js Pack, Firefox Debugger, Jest |
| **python** | Python 개발 | Python, Pylance, Black, Flake8 |
| **rust** | Rust 개발 | Rust Analyzer, TOML, Crates |
| **optional** | 선택 확장 | Dracula/Nord 테마, Hex Editor, Markdown |

## 🚀 CLI 방식 (자동화/CI)

### 1️⃣ 단일 언어 개발자

```bash
# Java 개발자
./easy-setup.sh --preset java-dev --vscode-extras java --execute

# Python 개발자
./easy-setup.sh --preset python-dev --vscode-extras python --execute

# Rust 개발자
./easy-setup.sh --preset rust-dev --vscode-extras rust --execute
```

### 2️⃣ 다중 언어 개발자 (권장)

```bash
# Java + .NET 개발자
./easy-setup.sh --preset java-dev --vscode-extras java,dotnet --execute

# Java + .NET + Node.js 개발자
./easy-setup.sh --preset full-dev --vscode-extras java,dotnet,node --execute

# 풀스택 + 선택 확장 (테마 포함)
./easy-setup.sh --preset fullstack-dev --vscode-extras node,python,optional --execute
```

### 3️⃣ Dry Run (미리 확인)

```bash
# 설치 전 어떤 확장이 설치될지 확인
./easy-setup.sh --preset java-dev --vscode-extras java,dotnet --dry-run
```

## 🖥️ TUI 방식 (대화형)

### 사용 절차

```bash
# 터미널에서 실행
./easy-setup.sh
```

1. **모드 선택**: "직접 선택 (Custom Selection)" 선택
2. **모듈 선택**: `gui.vscode` 선택 후 계속
3. **VSCode 확장 선택**: 필요한 개발 유형 선택
   ```
   ✓ Base (Required)
   ☐ java
   ☑ dotnet
   ☑ node
   ☐ python
   ☐ rust
   ☐ optional
   ```
4. **최종 검토**: 선택 사항 확인 후 설치

또는 프리셋으로 로드 후:
```bash
./easy-setup.sh java-dev
# → VSCode 확장 선택 화면 표시
```

## 📂 확장 그룹 구조

```
modules/gui/vscode/
├── install.sh                 # VSCode 설치 + 확장 그룹 처리
├── meta.json
└── extensions/
    ├── base.json              # 공통 확장
    ├── java.json              # Java 관련
    ├── dotnet.json            # .NET 관련
    ├── node.json              # Node.js 관련
    ├── python.json            # Python 관련
    ├── rust.json              # Rust 관련
    └── optional.json          # 선택 확장
```

각 JSON 파일 형식:
```json
{
  "name": "Java Developer Extensions",
  "description": "Java 개발 관련 확장",
  "extensions": [
    "redhat.java",
    "vscjava.vscode-maven",
    "vscjava.vscode-spring-boot",
    ...
  ]
}
```

## 🔧 확장 그룹 커스터마이징

### 기존 확장 추가/수정

`modules/gui/vscode/extensions/java.json` 수정:

```json
{
  "name": "Java Developer Extensions",
  "description": "Java 개발 관련 확장",
  "extensions": [
    "redhat.java",
    "vscjava.vscode-maven",
    "vscjava.vscode-spring-boot",
    "vscjava.vscode-gradle",
    "sonarlint.sonarlint",
    "my-custom-extension"  // 추가
  ]
}
```

### 새로운 확장 그룹 만들기

`modules/gui/vscode/extensions/golang.json` 생성:

```json
{
  "name": "Go Developer Extensions",
  "description": "Go 개발 관련 확장",
  "extensions": [
    "golang.go",
    "ms-vscode.go",
    "nametag.gomodifytags"
  ]
}
```

그 후 CLI에서 사용:
```bash
./easy-setup.sh --preset base --vscode-extras golang --execute
```

## 💡 사용 시나리오 예제

### 시나리오 1: 엔터프라이즈 개발자
Java 백엔드 + .NET 서비스 개발

```bash
./easy-setup.sh --preset java-dev \
  --vscode-extras java,dotnet \
  --execute
```

### 시나리오 2: 풀스택 개발자
Node.js + Python + 선택 테마

```bash
./easy-setup.sh --preset fullstack-dev \
  --vscode-extras node,python,optional \
  --execute
```

### 시나리오 3: 다양한 언어 개발자
모든 개발 도구 설치

```bash
./easy-setup.sh --preset full-dev \
  --vscode-extras java,dotnet,node,python,rust,optional \
  --execute
```

## 📝 주의사항

1. **base는 자동 포함**: `--vscode-extras` 지정 시 base 확장은 자동으로 포함됩니다.
2. **중복 제거**: 같은 확장이 여러 그룹에 있어도 한 번만 설치됩니다.
3. **네트워크 필요**: 확장 설치 시 인터넷 연결이 필요합니다.
4. **설치 순서**: 모듈 설치 후 VSCode 확장이 설치됩니다.

## 🔄 이미 설치된 VSCode에 확장 추가

VSCode가 이미 설치되어 있고 확장만 추가하려면:

```bash
# VSCode 설치 스킵 (확장만 설치)
./easy-setup.sh --preset java-dev --vscode-extras java,dotnet --execute
```

또는 직접 VSCode install.sh 실행:
```bash
modules/gui/vscode/install.sh java dotnet
```

## ❓ FAQ

**Q: 확장 설치에 실패하면?**
A: 인터넷 연결 확인 후 다시 실행하세요. 개별 확장 설치 실패는 전체 프로세스를 중단하지 않습니다.

**Q: 이미 설치된 확장은?**
A: `code --install-extension` 명령어는 이미 설치된 확장도 안전하게 처리합니다.

**Q: TUI에서 확장 선택 안 보이면?**
A: VSCode 모듈이 선택되지 않았거나, 비대화형 모드일 수 있습니다. `--vscode-extras` 옵션으로 CLI 사용하세요.

**Q: 특정 버전 확장 설치?**
A: `extensions.json`에서 `extensionId@version` 형식으로 지정:
```json
"extensions": [
  "redhat.java@1.20.0"
]
```
