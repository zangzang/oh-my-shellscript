#!/bin/bash
set -e

echo "🌐 Open WebUI 설치 중 (Docker)..."

# GPU 지원 여부 확인
GPU_FLAG=""
if command -v nvidia-smi &>/dev/null; then
    echo "✨ GPU 가속 모드로 실행합니다."
    GPU_FLAG="--gpus all"
fi

# 컨테이너 실행
# Ollama가 호스트에서 돌고 있으므로, 호스트 네트워킹을 사용하거나 
# 특수 주소(host.docker.internal)를 사용하여 연동합니다.
docker run -d \
  -p 3000:8080 \
  $GPU_FLAG \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "✅ Open WebUI 설치 완료!"
echo "🌐 브라우저에서 접속: http://localhost:3000"
