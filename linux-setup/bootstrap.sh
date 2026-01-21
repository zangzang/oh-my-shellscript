#!/bin/bash
#
# Linux Setup Assistant - 부트스트랩 스크립트
# Python TUI 실행을 위한 사전 준비
#
set -e

echo "🚀 Linux Setup Assistant 부트스트랩"
echo "=================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Python3 확인
log_info "Python3 확인 중..."
if ! command -v python3 &>/dev/null; then
    log_warn "Python3가 설치되어 있지 않습니다. 설치 중..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3 python3-pip
    elif command -v yum &>/dev/null; then
        sudo yum install -y python3 python3-pip
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm python python-pip
    else
        log_error "패키지 관리자를 찾을 수 없습니다. Python3를 수동으로 설치해주세요."
        exit 1
    fi
fi

PYTHON_VERSION=$(python3 --version 2>&1)
log_info "Python 버전: $PYTHON_VERSION"

# 2. pip 확인 및 업그레이드
log_info "pip 확인 중..."
if ! python3 -m pip --version &>/dev/null; then
    log_warn "pip가 없습니다. 설치 중..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y python3-pip
    else
        curl -sS https://bootstrap.pypa.io/get-pip.py | python3
    fi
fi

# 3. textual 설치
log_info "textual 라이브러리 확인 중..."
if ! python3 -c "import textual" 2>/dev/null; then
    log_info "textual 설치 중..."
    python3 -m pip install --user textual
fi

TEXTUAL_VERSION=$(python3 -c "import textual; print(textual.__version__)" 2>/dev/null || echo "unknown")
log_info "textual 버전: $TEXTUAL_VERSION"

# 4. 터미널 환경 확인
log_info "터미널 환경 확인 중..."
if [[ -z "$TERM" ]]; then
    export TERM=xterm-256color
    log_warn "TERM 환경변수 설정: xterm-256color"
fi

# 5. config 디렉토리 확인
if [[ ! -d "$SCRIPT_DIR/config" ]]; then
    log_warn "config 디렉토리가 없습니다. 기본 설정 생성 중..."
    mkdir -p "$SCRIPT_DIR/config"
    
    # 기본 categories.json 생성
    cat > "$SCRIPT_DIR/config/categories.json" << 'EOF'
{
  "system": {
    "name": "🔧 System",
    "order": 1,
    "modules": ["update", "build-tools", "essentials", "dev-libs", "cli-tools", "nerd-fonts", "oh-my-posh", "zsh", "shell-config", "ssh-server"]
  },
  "tools": {
    "name": "🛠️ Tools",
    "order": 2,
    "modules": ["fastfetch"]
  },
  "dev": {
    "name": "💻 Development",
    "order": 3,
    "subcategories": {
      "runtime": {
        "name": "Runtime & SDK",
        "modules": ["nvm", "node", "python", "java", "sdkman", "dotnet", "rust"]
      },
      "build": {
        "name": "Build Tools",
        "modules": ["maven", "gradle"]
      },
      "container": {
        "name": "Container & Infra",
        "modules": ["docker", "docker-stack"]
      },
      "mobile": {
        "name": "Mobile & Desktop",
        "modules": ["flutter", "android", "tauri"]
      },
      "ai": {
        "name": "AI & ML",
        "modules": ["cuda", "ollama", "ollama-models", "open-webui"]
      }
    },
    "modules": []
  },
  "gui": {
    "name": "🖥️ GUI Apps",
    "order": 4,
    "modules": ["vscode", "chrome", "dbeaver", "sts", "fcitx5"]
  }
}
EOF
fi

echo ""
echo "=================================="
log_info "부트스트랩 완료!"
echo ""
echo "실행 방법:"
echo "  cd $SCRIPT_DIR"
echo "  python3 setup.py"
echo ""
echo "옵션:"
echo "  python3 setup.py --preset java-dev     # 프리셋 로드"
echo "  python3 setup.py --preset base --execute  # 바로 설치"
echo ""

# 바로 실행할지 묻기
read -p "지금 바로 실행하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$SCRIPT_DIR"
    exec python3 setup.py "$@"
fi
