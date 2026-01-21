# Copilot Instructions for Cross-Platform Setup Assistant

이 프로젝트는 **Windows 및 Linux 환경**의 반복적인 개발 환경 설정 작업을 자동화하기 위한 **모듈식 설정 관리 시스템**입니다.

### 📌 프로젝트 구성
- **Linux 자동화**: `linux-setup/` - Bash + fzf 기반 TUI 설치 자동화
- **Windows 자동화**: `pwsh/` - PowerShell 기반 환경 설정  
- **Bash 유틸리티**: `bash/` - 공유 Bash 스크립트 및 설정 파일

## 🎯 프로젝트 개요

- **목적**: OS 재설치/신규 환경 구축 시 필요한 소프트웨어와 설정을 자동으로 수행
- **접근 방식**: 모듈화된 설치 스크립트 + fzf 기반 TUI 선택 인터페이스 (Linux) + PowerShell 스크립트 (Windows)
- **주요 기술**: Bash, PowerShell, JSON, `jq`, `fzf` (TUI 라이브러리)

## 📁 프로젝트 구조

```
my-shell-script/
├── .github/
│   └── copilot-instructions.md  # 이 파일 (Copilot AI 가이드)
├── bash/                        # Bash 공유 스크립트
│   ├── aliases.sh
│   ├── settup.sh
│   ├── oh-my-posh.omp.json
│   ├── ssh_up_se.sh
│   └── dotnet-install.sh
├── linux-setup/                 # Linux 자동화 시스템 ⭐
│   ├── easy-setup.sh           # 메인 진입점 (fzf 기반 TUI)
│   ├── README.md               # Linux 설정 가이드
│   ├── config/                 # 설정 파일 (하드코딩 제거)
│   │   ├── categories.json    # 카테고리 트리 정의
│   │   └── ui.json            # UI 문자열/아이콘 정의
│   ├── lib/                    # 공통 함수 라이브러리
│   │   ├── core.sh            # 로깅, 권한 관리 등
│   │   ├── fzf-ui.sh          # fzf 기반 UI 함수
│   │   ├── preview.sh         # fzf 프리뷰 스크립트
│   │   └── validate.sh        # JSON 검증
│   ├── modules/                # 설치 모듈 저장소
│   │   ├── dev/               # 개발 도구 (Docker, Java, Node, Python 등)
│   │   ├── gui/               # GUI 애플리케이션 (VSCode, Chrome 등)
│   │   ├── system/            # 시스템 필수 요소 (apt 업데이트, 빌드도구 등)
│   │   └── tools/             # CLI 유틸리티 (fastfetch 등)
│   ├── presets/                # 사전 정의된 설치 조합
│   │   ├── base.json
│   │   ├── java-dev.json
│   │   └── ... (기타 프리셋)
│   ├── docs/                   # 추가 가이드 문서
│   │   ├── JAVA_GUIDE.md
│   │   ├── PERMISSIONS.md
│   │   ├── REMOTE_SETUP_GUIDE.md
│   │   └── VSCODE_EXTENSIONS_GUIDE.md
│   └── test/                   # 설치 후 테스트 결과 디렉토리
├── pwsh/                       # PowerShell 스크립트
│   ├── Set-DevEnv.ps1
│   └── Set-PackageCacheEnv.ps1
└── windows-setup/              # Windows 자동화 시스템 (향후 확장)
```

### 핵심 구성요소

1. **easy-setup.sh**: 상태 머신(State Machine) 기반 오케스트레이터
   - TUI 메뉴 제공 (gum 사용)
   - 의존성 자동 해결
   - 모듈 순차 실행

2. **modules/{category}/{name}/**: 각 기능의 격리된 단위
   - `meta.json`: 모듈 메타데이터 및 의존성 정의
   - `install.sh`: 실제 설치/설정 로직

3. **presets/*.json**: 특정 용도의 모듈 집합 정의

## ✅ 모듈 생성 규칙

### 1. 디렉토리 구조

새로운 기능은 **반드시 모듈로 분리**해야 합니다.

```bash
modules/<category>/<name>/
├── meta.json      # [필수] 모듈 메타데이터
└── install.sh     # [필수] 설치 스크립트
```

**카테고리 분류**:
- `dev`: 개발 환경 (Docker, Node.js, Python 등)
- `gui`: GUI 애플리케이션 (Chrome, VSCode, DBeaver 등)
- `system`: 시스템 필수 요소 (빌드 도구, 라이브러리 등)
- `tools`: CLI 유틸리티 (fastfetch, fzf 등)

### 2. meta.json 작성

```json
{
  "id": "category.name",              // [필수] 고유 식별자 (형식: 카테고리.이름)
  "name": "Display Name",             // [필수] TUI에 표시될 이름
  "description": "What it does",      // [선택] 설명문
  "category": "dev",                  // [필수] 카테고리 (폴더명과 일치)
  "requires": ["system.update"],      // [선택] 의존 모듈 ID 배열
  "variants": {                       // [선택] 버전/변형 지원
    "latest": { "version": "latest" },
    "lts": { "version": "20.x" }
  }
}
```

**필드 설명**:
- `id`: `category.name` 형식 준수 (예: `dev.docker`, `gui.chrome`)
- `requires`: 이 모듈 실행 전에 필요한 다른 모듈들
- `variants`: 여러 버전을 지원할 경우 정의 (프리셋에서 `id:variant` 형식으로 선택)

### 3. install.sh 작성

#### 기본 템플릿

```bash
#!/bin/bash
set -e  # 에러 발생 시 즉시 중단

# 1. 이미 설치되어 있는지 확인 (멱등성)
if command -v <tool> &>/dev/null; then
    echo "<Tool> 이미 설치됨 ($(which <tool>))"
    exit 0
fi

# 2. 설치 로직
echo "<Tool> 설치 중..."
# ... 실제 설치 명령어 ...

# 3. 검증 (선택 사항)
if command -v <tool> &>/dev/null; then
    echo "<Tool> 설치 완료"
    exit 0
else
    echo "<Tool> 설치 실패"
    exit 1
fi
```

### 4. test.sh 작성 (선택 사항)

각 모듈에 `test.sh`를 추가하면 설치 후 자동으로 Hello World 테스트가 실행됩니다.

#### 테스트 파일 위치 규칙

- **테스트 디렉토리**: `linux-setup/test/{모듈id}/`
- 예: `dev.dotnet` → `linux-setup/test/dev.dotnet/`
- 예: `dev.java` → `linux-setup/test/dev.java/`

#### 테스트 템플릿

```bash
#!/bin/bash
set -e

echo "🧪 <Tool> 설치 테스트 중..."

# 1. 명령어 존재 확인
if ! command -v <tool> &>/dev/null; then
    echo "❌ <tool> 명령을 찾을 수 없습니다."
    exit 1
fi

# 2. 버전 확인
echo "✅ <Tool> 버전: $(<tool> --version)"

# 3. 테스트 디렉토리 생성 (모듈 ID 기반)
MODULE_ID="category.name"  # 예: dev.dotnet, dev.java
TEST_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../test" && pwd)"
TEST_DIR="$TEST_BASE_DIR/$MODULE_ID"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 4. Hello World 실행
echo "📝 Hello World 생성 중..."
# ... 테스트 코드 작성 ...

echo "🚀 실행 중..."
OUTPUT=$(<실행 명령> 2>&1)

# 5. 결과 확인 및 위치 안내
if echo "$OUTPUT" | grep -q "Hello"; then
    echo "✅ 출력: $OUTPUT"
    echo "✅ <Tool> 테스트 통과!"
    echo "📁 테스트 파일 위치: $TEST_DIR"
    exit 0
else
    echo "❌ 예상치 못한 출력: $OUTPUT"
    echo "📁 테스트 파일 위치: $TEST_DIR"
    exit 1
fi
```

**주의사항**:
- 테스트 파일/폴더는 삭제하지 않음 (사용자가 확인할 수 있도록)
- 테스트 실패해도 설치는 계속 진행 (경고만 표시)
- `TEST_DIR` 변수에 테스트 위치를 명확히 저장

**환경 변수 설정**:
- 설치 직후 테스트 시 PATH에 명령어가 없을 수 있음
- 각 도구별로 필요한 환경 변수를 test.sh 시작 부분에 설정:
  ```bash
  # .NET
  export PATH="$HOME/.dotnet:$PATH"
  
  # NVM/Node.js
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  # SDKMAN/Java
  export SDKMAN_DIR="$HOME/.sdkman"
  [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
  
  # Rust/Cargo
  export PATH="$HOME/.cargo/bin:$PATH"
  ```

**테스트 서버 정보**:
- **호스트**: `10.100.10.40`
- **계정**: `jwjang`
- **비밀번호**: `200812jj`
- **용도**: 원격 설치 및 테스트 검증

**원격 서버 테스트 시**:
1. **전체 프로젝트 복사** (초기 배포 시):
   ```bash
   cd /home/jwjang/ws/zangzang/my-shell-script
   scp -r linux-setup jwjang@10.100.10.40:~/
   ```

2. **모듈 복사** (개별 모듈 업데이트 시):
   ```bash
   scp -r modules/dev/<module> jwjang@10.100.10.40:~/linux-setup/modules/dev/
   ```

3. **NOPASSWD 설정** (필수, 처음 한 번만):
   ```bash
   # 로컬에서 원격 설정 (비밀번호 입력 필요)
   ssh jwjang@10.100.10.40 "echo '200812jj' | sudo -S sh -c 'echo \"jwjang ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/jwjang' && echo '200812jj' | sudo -S chmod 440 /etc/sudoers.d/jwjang"
   ```

4. **테스트 실행**: 설치 후 자동으로 test.sh가 실행됨
   ```bash
   ssh jwjang@10.100.10.40 "cd ~/linux-setup && ./easy-setup.sh --preset java-dev --execute"
   ```

**주의사항**:
- NOPASSWD 미설정 시 sudo 프롬프트에서 스크립트가 중단됨
- 보안이 중요한 환경에서는 특정 명령만 NOPASSWD 허용 권장:
  ```
  jwjang ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/systemctl
  ```

#### 필수 원칙

1. **멱등성 (Idempotency)**: 여러 번 실행해도 안전해야 함
   - 이미 설치된 경우 건너뛰기
   - 설정 파일이 있으면 백업 후 덮어쓰기

2. **명확한 출력**: 사용자가 무슨 일이 일어나는지 알 수 있도록
   ```bash
   echo "Docker 설치 중..."
   echo "Docker 그룹에 사용자 추가 중..."
   ```

3. **Exit Code 관리**:
   - 성공: `exit 0`
   - 실패: `exit 1` 이상

4. **환경 변수 전달**: 프리셋에서 정의한 파라미터는 환경변수로 전달됨
   ```bash
   VERSION="${VERSION:-latest}"  # 기본값 설정
   ```

## 🔧 코딩 컨벤션

### Bash 스크립트

```bash
#!/bin/bash
set -e  # 에러 시 중단 (필수)

# 변수명: UPPER_CASE for globals, lower_case for locals
INSTALL_DIR="/opt/myapp"
local temp_file="/tmp/config"

# 함수 정의
install_package() {
    local pkg_name=$1
    echo "Installing ${pkg_name}..."
    sudo apt-get install -y "$pkg_name"
}

# 조건문: [[ ]] 사용 (bash 권장)
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Config exists"
fi

# 명령어 존재 확인
if command -v docker &>/dev/null; then
    echo "Docker is available"
fi
```

### JSON 작성

- **들여쓰기**: 2 스페이스
- **따옴표**: 큰따옴표만 사용
- **주석 불가**: JSON은 주석을 지원하지 않음 (설명은 `description` 필드 활용)

## 🔗 의존성 관리

### 원칙

- **명시적 선언**: `meta.json`의 `requires` 필드에 모든 의존성 명시
- **순환 참조 금지**: A → B → A 같은 의존성 불가
- **자동 해결**: `easy-setup.sh`가 의존성 그래프를 자동으로 해결

### 예시

```json
// modules/dev/nvm/meta.json
{
  "id": "dev.nvm",
  "name": "NVM (Node Version Manager)",
  "requires": ["system.build-tools"]  // curl, git 필요
}
```

### 주의사항

- 다른 모듈의 기능이 필요하면 `install.sh`에서 직접 호출하지 말고 `requires`에 추가
- 시스템 업데이트가 필요한 경우 `system.update`를 의존성에 포함

## 📦 프리셋 작성

프리셋은 특정 목적을 위한 모듈 조합입니다.

```json
{
  "name": "Full Stack Developer Setup",
  "description": "Node.js, Python, Docker, VSCode",
  "modules": [
    { "id": "system.update" },
    { "id": "system.build-tools" },
    { "id": "dev.nvm" },
    { "id": "dev.python" },
    { "id": "dev.docker" },
    { "id": "gui.vscode" }
  ]
}
```

### Variant 사용

```json
{
  "modules": [
    { "id": "dev.java", "params": { "version": "17" } }
  ]
}
```

## 🚨 금지 사항

### ❌ 하지 말아야 할 것

1. **easy-setup.sh에 설치 로직 추가**
   - 모든 설치는 모듈로 분리
   - 오케스트레이터는 실행 흐름만 관리

2. **install.sh에서 다른 모듈 직접 호출**
   ```bash
   # ❌ 금지
   bash ../docker/install.sh
   
   # ✅ 올바른 방법: meta.json에 의존성 추가
   "requires": ["dev.docker"]
   ```

3. **하드코딩된 경로 사용**
   ```bash
   # ❌ 금지
   /home/user/Downloads/file
   
   # ✅ 올바른 방법
   "$HOME/Downloads/file"
   ```

4. **대화형 프롬프트**
   ```bash
   # ❌ 금지 (자동화 불가)
   read -p "Continue? (y/n): " answer
   
   # ✅ 올바른 방법: 환경변수로 제어 또는 무조건 실행
   ```

5. **Sudo 비밀번호 요구하는 긴 작업**
   - 스크립트 시작 시 `sudo -v`로 캐시 갱신
   - 또는 sudo 없이 가능한 방법 고려

## 🛠️ 공통 유틸리티 (lib/core.sh)

### 로깅 함수

```bash
source "$SCRIPT_DIR/lib/core.sh"

log_info "Starting installation..."      # 파란색
log_success "Installation complete!"     # 녹색
log_warn "Config not found, using default"  # 노란색
log_error "Installation failed!"         # 빨간색
```

### 유틸리티 함수

```bash
ensure_utils     # jq, gum 설치 확인 및 자동 설치
check_os         # Ubuntu 기반 확인
check_network    # 인터넷 연결 확인
```

## 📝 새 모듈 추가 예시

### 시나리오: Git 설치 모듈 추가

1. **디렉토리 생성**
   ```bash
   mkdir -p modules/dev/git
   ```

2. **meta.json 작성**
   ```json
   {
     "id": "dev.git",
     "name": "Git",
     "description": "Git version control system",
     "category": "dev",
     "requires": ["system.update"]
   }
   ```

3. **install.sh 작성**
   ```bash
   #!/bin/bash
   set -e
   
   if command -v git &>/dev/null; then
       echo "Git 이미 설치됨 ($(git --version))"
       exit 0
   fi
   
   echo "Git 설치 중..."
   sudo apt-get install -y git
   
   echo "Git 설치 완료"
   git --version
   ```

4. **권한 설정**
   ```bash
   chmod +x modules/dev/git/install.sh
   ```

5. **테스트**
   ```bash
   ./easy-setup.sh  # TUI에서 "Git" 모듈 확인
   ```

## 🧪 테스트 가이드

### Dry Run 활용

```bash
# 1. TUI 실행
./easy-setup.sh

# 2. 모듈 선택 후 "시뮬레이션" 선택
# 3. 실제 설치 없이 실행 순서 확인
```

### 단일 모듈 테스트

```bash
cd modules/dev/docker
bash install.sh  # 직접 실행하여 테스트
```

## 🎨 Copilot 활용 팁

### 요청 예시

✅ **좋은 요청**:
- "dev.nodejs 모듈 생성해줘. NVM을 이용해서 설치하고 system.build-tools에 의존해야 해"
- "base 프리셋에 fastfetch 모듈 추가해줘"
- "install.sh가 이미 설치된 경우를 확인하도록 수정해줘"

❌ **피해야 할 요청**:
- "easy-setup.sh에 Python 설치 코드 추가해줘" (모듈로 분리 필요)
- "이 스크립트를 Windows PowerShell로 변환해줘" (현재 프로젝트는 Linux 전용)

### 코드 생성 시 체크리스트

Copilot이 생성한 코드를 적용하기 전에 확인하세요:

- [ ] `meta.json`의 `id`가 `category.name` 형식인가?
- [ ] `install.sh`에 `#!/bin/bash` 있는가?
- [ ] 멱등성이 보장되는가? (재실행 시 안전한가?)
- [ ] 에러 처리가 있는가? (`set -e` 또는 조건문)
- [ ] 의존성이 `meta.json`에 선언되어 있는가?

## 📚 참고 자료

### 기존 모듈 참고

- **간단한 예시**: [linux-setup/modules/tools/fastfetch/](linux-setup/modules/tools/fastfetch/)
- **의존성 있는 예시**: [linux-setup/modules/dev/docker/](linux-setup/modules/dev/docker/)
- **다중 변형 예시**: [linux-setup/modules/dev/java/](linux-setup/modules/dev/java/)

### 외부 문서

- [Bash Scripting Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [gum TUI Library](https://github.com/charmbracelet/gum)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

**마지막 업데이트**: 2026-01-09
**프로젝트 버전**: 2.0 (Modular Refactoring)
