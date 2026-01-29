#!/usr/bin/env pwsh
# Nerd Fonts 설치 (Cascadia Code Nerd Font 추천)

Write-LogInfo "Nerd Fonts (Cascadia Code) 설치 중..."
# Cascadia Code는 Nerd Font를 포함하는 버전이 winget에 있음
Install-WithWinget -Id "Microsoft.CascadiaCode" -Name "Cascadia Code" -DryRun:$(Test-DryRunMode)
