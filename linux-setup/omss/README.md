# Go + Bubble Tea Setup Migration

Python 기반 `textual` TUI에서 Go 기반 `Bubble Tea` TUI로 마이그레이션되었습니다.

## 🚀 설치 및 실행

### Go 환경 준비
```bash
# Go 설치 확인
go version

# 의존성 다운로드
cd linux-setup/omss
go mod tidy
```

### 빌드 및 실행

```bash
# 바이너리 빌드
cd linux-setup/omss
go build -o bin/setup ./cmd/setup

# 또는 래퍼 스크립트 사용
./omss.sh

# --preset 옵션과 함께 실행
./omss.sh --preset base --dry-run

# 대화형 설치
./omss.sh
```

## 📦 프로젝트 구조

```
linux-setup/omss/
├── cmd/setup/              # 메인 진입점
│   └── main.go
├── internal/
│   ├── config/             # 설정 및 경로 관리
│   │   └── paths.go
│   ├── module/             # 모듈 관리 및 설치 로직
│   │   ├── types.go        # 데이터 구조
│   │   ├── manager.go      # ModuleManager 구현
│   │   └── installer.go    # 설치 로직
│   └── ui/                 # Bubble Tea UI
│       ├── ui.go           # 메인 UI 모델
│       └── styles.go       # 스타일링
├── go.mod                  # Go 모듈 정의
└── go.sum                 # 의존성 잠금

omss.sh                    # 래퍼 스크립트
```

## 🔧 주요 기능

### 1. ModuleManager
- 모듈 메타데이터 로딩 (`meta.json` 파싱)
- 카테고리 및 서브카테고리 자동 할당
- 의존성 해석 (dependency resolution)
- 프리셋 로드/저장

### 2. Bubble Tea UI
- 대화형 모듈 선택
- 실시간 검색 (`/` 키)
- 키보드 네비게이션
- 색상 및 스타일링 (lipgloss)

### 3. Installer
- 드라이 런 모드 (`--dry-run`)
- 지정된 설치 스크립트 실행
- 설치 진행 상황 표시

## 🎮 키보드 바인딩

| 키 | 기능 |
|:---:|:---|
| `↑/k` | 위로 이동 |
| `↓/j` | 아래로 이동 |
| `Space` | 모듈 선택/해제 |
| `/` | 검색 시작 |
| `Enter` | 검색 완료 |
| `Esc` | 검색 취소 |
| `F5` | 설치 시작 |
| `q` | 종료 |
| `Home` | 처음으로 |
| `End` | 마지막으로 |

## 💻 명령어 옵션

```bash
# 대화형 UI 실행
./omss.sh

# 프리셋으로 실행
./omss.sh --preset java-dev

# 즉시 실행 (확인 없음)
./omss.sh --preset node-dev --execute

# 설치 계획만 보기
./omss.sh --preset python-dev --dry-run

# Post Module 실행 정책 지정 (always|selected|preset)
./omss.sh --post-module-mode selected --preset java-dev --dry-run

# 환경변수로 정책 지정
OMSS_POST_MODULE_MODE=always ./omss.sh --preset full-dev --dry-run
```

### Post Module 정책

- `selected` (기본값): 명시적으로 선택한 모듈의 `post_modules`만 실행
- `always`: 의존성으로 포함된 모듈도 `post_modules` 실행
- `preset`: 프리셋에서 명시된 모듈의 `post_modules`만 실행

예: `dev.sdkman`의 `post_modules`에 `dev.maven`, `dev.gradle`가 있으면,
- `selected`/`preset`에서는 SDKMAN을 직접 선택(또는 프리셋에 명시)했을 때만 Maven/Gradle 자동 포함
- `always`에서는 의존성으로 SDKMAN이 포함되어도 Maven/Gradle 자동 포함

## 📝 마이그레이션 포인트

### Python Textual → Go Bubble Tea

| 기능 | Python | Go |
|:---|:---|:---|
| TUI 프레임워크 | `textual` | `bubbletea` |
| 스타일링 | Textual CSS | `lipgloss` |
| 모듈 관리 | `ModuleManager` | `module.Manager` |
| 설치 로직 | `run_installation()` | `Installer` 구조체 |
| 프리셋 처리 | JSON 파싱 | JSON 파싱 |

## 🔄 호환성

- ✅ linux-setup 디렉토리의 모든 모듈 호환
- ✅ 기존 `meta.json` 형식 호환
- ✅ 기존 프리셋 JSON 호환
- ✅ 명령어 라인 옵션 호환

## 🐛 알려진 제한 사항

1. 프리셋 선택 시UI에서는 직접 선택 미지원 (--preset 플래그로 사용)
2. 설치 중 대화형 입력은 기본 구현 (향후 개선 가능)

## 📚 비교: Python vs Go

### 장점 (Go)
- 🚀 더 빠른 시작 시간 (네이티브 바이너리)
- 📦 외부 의존성 없음 (단일 바이너리)
- 🎯 타입 안전성
- 🔧 더 효율적인 메모리 사용

### 장점 (Python)
- 🎨 더 풍부한 UI 커스터마이징 가능 (Textual)
- 📖 더 빠른 개발 속도
- 🔌 더 많은 플러그인 생태계

## 🚀 향후 개선

- [ ] 색상 테마 설정
- [ ] 모듈 설명 표시 패널
- [ ] 설치 로그 저장
- [ ] 재실행 기능
- [ ] 더 나은 프리셋 UI 선택
- [ ] 병렬 설치 지원

## 📜 라이센스

이 프로젝트는 기존 oh-my-shellscript 프로젝트와 동일한 라이센스를 따릅니다.
