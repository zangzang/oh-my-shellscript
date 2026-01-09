# 권한 관리 가이드

## 문제 상황

프로젝트를 압축(tar, zip 등)하여 다른 시스템으로 이동하면 실행 권한이 손실될 수 있습니다.

## 해결 방법

### ✅ 방법 1: 자동 복구 (권장)

`easy-setup.sh`가 시작할 때 자동으로 권한을 체크하고 복구합니다.

```bash
# 그냥 실행하면 됩니다
bash easy-setup.sh
```

**동작 방식:**
- 스크립트 시작 시 모든 `install.sh` 파일의 실행 권한 체크
- 권한이 없는 파일 자동 감지 및 복구
- 수정된 파일 수를 로그로 표시

### ✅ 방법 2: 수동 일괄 부여

별도의 권한 부여 스크립트를 제공합니다.

```bash
# 권한 부여 스크립트 실행
bash fix-permissions.sh
```

**처리 내용:**
- `modules/*/install.sh` 전체 (23개)
- `easy-setup.sh`
- 각 파일의 상대 경로 표시

## 테스트 결과

```bash
# 권한 제거 (테스트)
$ chmod -x modules/system/zsh/install.sh

# 자동 복구 확인
$ bash easy-setup.sh
[INFO] 실행 권한 수정됨: 1개 파일

# 권한 확인
$ ls -la modules/system/zsh/install.sh
-rwxrwxr-x modules/system/zsh/install.sh  # ✅ 복구됨
```

## 압축 시 권한 유지 방법

### tar 사용 시 (권장)

```bash
# 압축 (권한 유지)
tar -czf linux-setup.tar.gz linux-setup/

# 압축 해제 (권한 유지)
tar -xzf linux-setup.tar.gz
```

### zip 사용 시

```bash
# 압축 (권한 유지 옵션)
zip -r linux-setup.zip linux-setup/ -x "*.git*"

# 압축 해제
unzip linux-setup.zip
```

**주의:** zip은 Unix 권한을 완벽하게 유지하지 못할 수 있으므로 tar를 권장합니다.

## Git 저장소 사용 시

Git은 실행 권한을 자동으로 추적합니다.

```bash
# 권한 확인
git ls-files --stage modules/*/install.sh

# 100755 = 실행 권한 있음
# 100644 = 실행 권한 없음

# 권한 추가 후 커밋
chmod +x modules/*/install.sh
git add .
git commit -m "Add execute permissions"
```

## Sudo 권한 설정 (원격 스크립트 자동화)

### ⚙️ 방법 1: NOPASSWD 설정 (권장)

원격 서버에서 스크립트를 비밀번호 입력 없이 자동 실행하려면 sudoers 파일을 수정합니다.

**설정 방법:**

```bash
# 1. sudoers 파일 안전하게 편집
sudo visudo

# 2. 파일 끝에 다음 추가
jwjang ALL=(ALL) NOPASSWD: ALL

# 또는 특정 명령만 허용 (더 안전)
jwjang ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/systemctl, /usr/sbin/useradd
```

**스크립트 사용 예:**

```bash
#!/bin/bash
# NOPASSWD 설정되면 비밀번호 프롬프트 없이 실행됨
sudo apt update
sudo apt install -y docker.io
sudo systemctl restart nginx
```

**장점:**
- 스크립트 중단 없이 연속 실행 가능
- 완전 자동화 가능
- 한 번만 설정하면 됨

### ⚙️ 방법 2: sudo -S 비밀번호 파이프 (NOPASSWD 미설정 시)

NOPASSWD를 설정하지 않았을 때 비밀번호를 자동으로 입력합니다.

**원격 실행 예:**

```bash
# 로컬에서 원격 서버 스크립트 실행
ssh jwjang@10.100.10.40 "echo '비밀번호' | sudo -S 명령어"

# 구체적 예
ssh jwjang@10.100.10.40 "echo 'mypassword' | sudo -S apt update -y"
```

**스크립트 내 사용 예:**

```bash
#!/bin/bash
PASSWORD="mypassword"

# 각 sudo 명령 실행
echo "$PASSWORD" | sudo -S apt update -y
echo "$PASSWORD" | sudo -S apt install -y docker.io
echo "$PASSWORD" | sudo -S systemctl restart nginx
```

**주의사항:**
- 비밀번호가 히스토리 및 프로세스 목록에 노출될 수 있음
- 보안상 NOPASSWD가 더 권장됨
- 프로덕션 환경에서는 SSH 키 기반 인증 추가 권장

**비밀번호를 변수로 안전하게 관리:**

```bash
#!/bin/bash

# 파일에서 읽기 (파일 권한: 600)
PASSWORD=$(cat ~/.ssh/sudo_pass)

# 또는 환경변수에서 읽기
# PASSWORD=$SUDO_PASSWORD

echo "$PASSWORD" | sudo -S apt update -y
```

### 비교 표

| 방법 | 설정 필요 | 사용법 | 보안성 | 자동화 |
|------|---------|-------|-------|--------|
| NOPASSWD | ✅ (한 번) | `sudo 명령` | 중간 | ✅ 완전 자동 |
| sudo -S | ❌ | `echo 'pwd' \| sudo -S 명령` | 낮음 | ⚠️ 비밀번호 노출 |

## FAQ

**Q: 왜 압축하면 권한이 사라지나요?**
A: zip 같은 일부 압축 도구는 Unix 권한을 저장하지 않습니다. tar를 사용하면 권한이 유지됩니다.

**Q: Windows에서 압축하면?**
A: Windows 파일 시스템(NTFS)은 Unix 실행 권한 개념이 없어서 압축 시 권한 정보가 손실됩니다.

**Q: 매번 권한을 부여해야 하나요?**
A: 아니요. `easy-setup.sh`가 자동으로 처리하거나, 한 번만 `fix-permissions.sh`를 실행하면 됩니다.

**Q: NOPASSWD는 안전한가요?**
A: NOPASSWD 사용자는 비밀번호 없이 sudo 명령을 실행할 수 있으므로, 서버 접근 권한이 있으면 모든 권한을 획득할 수 있습니다. 특정 명령만 허용하거나 신뢰할 수 있는 서버에서만 사용하세요.

---

**업데이트:** 2026-01-09
