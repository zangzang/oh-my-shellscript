# 원격 서버 설정 및 자동화 가이드

## 개요

이 문서는 SSH를 통해 원격 서버에 linux-setup을 설치하고, sudo 비밀번호 입력 없이 자동화하는 방법을 설명합니다.

## 1. 초기 설정: NOPASSWD 구성

### 문제 상황
비대화형(non-interactive) 원격 실행 시 sudo 비밀번호 입력이 필요하면 스크립트가 중단됩니다:
```
[ERROR] 비대화형 실행에서 sudo 비밀번호 입력이 필요하여 진행할 수 없습니다.
```

### ✅ 해결 방법: sudoers NOPASSWD 설정

#### 방법 1: 로컬에서 원격 설정 (권장)
```bash
# 로컬 머신에서 실행
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "echo '200812jj' | sudo -S bash -c \
  'echo \"jwjang ALL=(ALL) NOPASSWD: ALL\" | tee -a /etc/sudoers.d/jwjang-nopasswd'"
```

**설명:**
- `echo '200812jj' | sudo -S`: 비밀번호를 stdin으로 전달
- `sudoers.d/jwjang-nopasswd` 파일 생성: visudo 없이 안전한 추가
- 이제 모든 sudo 명령이 비밀번호 없이 실행됨

#### 방법 2: 원격 서버에서 직접 설정
```bash
ssh -t jwjang@10.100.10.40

# 원격 서버에서 실행
echo '200812jj' | sudo -S visudo
# 파일 끝에 추가: jwjang ALL=(ALL) NOPASSWD: ALL
```

### 검증
```bash
ssh jwjang@10.100.10.40 "sudo -v && echo '✅ NOPASSWD 설정 완료'"
```

---

## 2. 원격 스크립트 실행 패턴

### 패턴 A: 단순 명령 실행
```bash
ssh -o StrictHostKeyChecking=no user@remote "command"
```

**예시: 프리셋 설치**
```bash
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "cd ~/linux-setup && ./easy-setup.sh --preset tauri-dev --execute"
```

### 패턴 B: 파일 전송 후 실행
```bash
# 1. 로컬 파일 → 원격 서버 전송
scp -r local/path/file user@remote:~/destination/

# 2. 원격 서버에서 설치
ssh -o StrictHostKeyChecking=no user@remote \
  "cd ~/destination && ./install.sh"
```

**실제 예시:**
```bash
# linux-setup 폴더 전체 전송
scp -r linux-setup jwjang@10.100.10.40:~/

# tauri 모듈 전송
scp -r linux-setup/modules/dev/tauri jwjang@10.100.10.40:~/linux-setup/modules/dev/

# 프리셋 전송
scp linux-setup/presets/tauri-dev.json jwjang@10.100.10.40:~/linux-setup/presets/
```

### 패턴 C: 대화형 입력이 필요한 경우
```bash
ssh -o StrictHostKeyChecking=no -t user@remote "interactive-command"
```

**예시: Tauri 앱 생성 (템플릿 선택 필요)**
```bash
ssh -o StrictHostKeyChecking=no -t jwjang@10.100.10.40 \
  "cd ~/ws/tauri && npm create tauri-app@latest test-app -- \
  --manager npm --ui-template vanilla --typescript false"
```

---

## 3. 완전 자동화 워크플로우

### 예시: 원격 서버에 Tauri 개발 환경 설치

#### Step 1: NOPASSWD 설정 (1회만)
```bash
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "echo '200812jj' | sudo -S bash -c \
  'echo \"jwjang ALL=(ALL) NOPASSWD: ALL\" | tee -a /etc/sudoers.d/jwjang-nopasswd'"
```

#### Step 2: 프로젝트 파일 전송
```bash
cd /local/project/path
scp -r linux-setup jwjang@10.100.10.40:~/
```

#### Step 3: 프리셋 설치 (자동화)
```bash
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "cd ~/linux-setup && ./easy-setup.sh --preset tauri-dev --execute"
```

#### Step 4: 앱 생성 및 빌드
```bash
# 앱 생성 (대화형 입력 필요)
ssh -o StrictHostKeyChecking=no -t jwjang@10.100.10.40 \
  "mkdir -p ~/ws/tauri && cd ~/ws/tauri && \
  npm create tauri-app@latest test-app -- \
  --manager npm --ui-template vanilla --typescript false"

# 의존성 설치 및 빌드 (자동화)
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "cd ~/ws/tauri/test-app && npm install && npm run tauri build"
```

---

## 4. 옵션: 특정 명령만 NOPASSWD 허용 (보안)

NOPASSWD를 전체 sudo 권한에 할당하는 것이 불편하면, 특정 명령만 허용할 수 있습니다:

```bash
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "echo '200812jj' | sudo -S bash -c \
  'cat >> /etc/sudoers.d/jwjang-nopasswd << EOF
jwjang ALL=(ALL) NOPASSWD: /usr/bin/apt
jwjang ALL=(ALL) NOPASSWD: /usr/bin/systemctl
jwjang ALL=(ALL) NOPASSWD: /usr/sbin/useradd
jwjang ALL=(ALL) NOPASSWD: /usr/sbin/usermod
EOF'"
```

---

## 5. 모듈 개발 시 원격 테스트

새로운 모듈을 개발할 때:

```bash
# 1. 로컬에서 모듈 개발
# linux-setup/modules/dev/mymodule/install.sh 작성

# 2. 원격 서버에 전송
scp -r linux-setup/modules/dev/mymodule jwjang@10.100.10.40:~/linux-setup/modules/dev/

# 3. 원격에서 테스트
ssh -o StrictHostKeyChecking=no jwjang@10.100.10.40 \
  "cd ~/linux-setup && bash modules/dev/mymodule/install.sh"

# 4. 에러 확인 및 수정
# 로컬에서 수정 → 다시 전송 → 테스트 반복
```

---

## 6. 트러블슈팅

### 문제: `Permission denied (publickey)`
**해결:**
- SSH 키 없이 비밀번호 인증 사용: `ssh -o PubkeyAuthentication=no user@remote`
- 또는 hosts 파일에 원격 서버 추가

### 문제: `Host key verification failed`
**해결:**
```bash
# 호스트 키 검증 비활성화 (원격 테스트 시)
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@remote "command"
```

### 문제: `sudo: authentication failure`
**해결:**
1. NOPASSWD 설정 확인: `sudo -l`
2. 비밀번호 재확인
3. sudoers 파일 검증: `sudo visudo -c`

### 문제: `command not found`
**해결:**
- 원격 서버에서 경로 확인: `which command`
- shell 환경 초기화: `ssh user@remote "bash -l -c 'command'"`

---

## 7. 자동화 스크립트 예시

원격 설정을 완전 자동화하는 bash 스크립트:

```bash
#!/bin/bash

REMOTE_USER="jwjang"
REMOTE_HOST="10.100.10.40"
SUDO_PASSWORD="200812jj"
LOCAL_PROJECT="/path/to/linux-setup"

# Step 1: NOPASSWD 설정
echo "[1] Setting up NOPASSWD..."
ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
  "echo '$SUDO_PASSWORD' | sudo -S bash -c \
  'echo \"$REMOTE_USER ALL=(ALL) NOPASSWD: ALL\" | tee -a /etc/sudoers.d/$REMOTE_USER-nopasswd'"

# Step 2: 프로젝트 전송
echo "[2] Transferring project..."
scp -r $LOCAL_PROJECT $REMOTE_USER@$REMOTE_HOST:~/

# Step 3: 프리셋 설치
echo "[3] Installing preset..."
ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST \
  "cd ~/linux-setup && ./easy-setup.sh --preset tauri-dev --execute"

echo "✅ Remote setup complete!"
```

---

## 참고 자료

- [PERMISSIONS.md](PERMISSIONS.md) - 로컬 권한 설정
- [README.md](../README.md) - 프리셋 및 모듈 사용법
- SSH 공식 문서: https://linux.die.net/man/1/ssh
- sudoers 공식 문서: https://linux.die.net/man/5/sudoers
