# 일반적으로 많이 사용하는 Alias 모음
# 사용법: source ~/common-aliases.sh 또는 .bashrc에서 참조

# ========== 기본 ls 명령어들 ==========
alias ll='ls -alF'          # 자세한 리스트 (권한, 크기, 날짜 포함)
alias la='ls -A'            # 숨김파일 포함 (. .. 제외)
alias l='ls -CF'            # 간단한 컬럼 형태
alias ls='ls --color=auto'  # 컬러 출력
alias lh='ls -lah'          # 사람이 읽기 쉬운 크기로 표시

# ========== 디렉토리 이동 ==========
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'           # 이전 디렉토리로

# ========== 파일 작업 ==========
alias cp='cp -i'            # 덮어쓰기 확인
alias mv='mv -i'            # 덮어쓰기 확인  
alias rm='rm -i'            # 삭제 확인
alias mkdir='mkdir -pv'     # 상위 디렉토리까지 생성, 상세 출력

# ========== 검색 및 찾기 ==========
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias hg='history | grep'

# ========== 시스템 정보 ==========
alias df='df -h'            # 사람이 읽기 쉬운 디스크 사용량
alias du='du -h'            # 사람이 읽기 쉬운 디렉토리 크기
alias free='free -h'        # 사람이 읽기 쉬운 메모리 정보
alias ps='ps aux'           # 자세한 프로세스 정보
alias top='htop'            # htop이 있으면 사용
alias ports='netstat -tulanp'

# ========== 네트워크 ==========
alias ping='ping -c 5'     # 5번만 ping
alias wget='wget -c'        # 중단된 다운로드 재개

# ========== Git 관련 (Git 사용자용) ==========
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# ========== Docker 관련 (Docker 사용자용) ==========
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'

# ========== 텍스트 에디터 ==========
alias vi='vim'
alias nano='nano -w'        # 긴 줄 자동 줄바꿈 방지

# ========== 편의성 ==========
alias c='clear'
alias x='exit'
alias reload='source ~/.bashrc'
alias bashrc='nano ~/.bashrc'
alias profile='nano ~/.profile'

# ========== 시간/날짜 ==========
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# ========== 압축 파일 ==========
alias tgz='tar -czf'        # tar.gz 압축
alias tgx='tar -xzf'        # tar.gz 압축 해제
alias tbz='tar -cjf'        # tar.bz2 압축  
alias tbx='tar -xjf'        # tar.bz2 압축 해제