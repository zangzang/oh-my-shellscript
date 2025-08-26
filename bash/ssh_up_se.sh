# SSH 보안 설정 스크립트(root 는 접속불가 , user: 키로만 접속)

# 1. 현재 설정 확인
echo "=== 현재 SSH 설정 ==="
grep -E "^#?PermitRootLogin|^#?PasswordAuthentication|^#?PubkeyAuthentication" /etc/ssh/sshd_config

# 2. 변경될 내용 미리보기
echo "=== 변경 예정 내용 ==="
sed \
  -e 's/^#PermitRootLogin.*/PermitRootLogin no/' \
  -e 's/^#PasswordAuthentication.*/PasswordAuthentication no/' \
  -e 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' \
  /etc/ssh/sshd_config | grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication"

# 3. 확인 후 실제 적용
read -p "계속하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] ]]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    sed -i \
      -e 's/^#PermitRootLogin.*/PermitRootLogin no/' \
      -e 's/^#PasswordAuthentication.*/PasswordAuthentication no/' \
      -e 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' \
      /etc/ssh/sshd_config
    echo "설정이 완료되었습니다."
fi