#!/bin/bash
set -e

MODEL="${1:-llama3.1}"

echo "📥 Ollama 모델 다운로드 중: $MODEL"

# Ollama 서비스가 응답할 때까지 잠시 대기
attempt=0
while ! ollama list &>/dev/null; do
    ((attempt++))
    if [ $attempt -gt 10 ]; then
        echo "❌ Ollama 서비스에 연결할 수 없습니다."
        exit 1
    fi
    echo "⏳ 서비스 응답 대기 중... ($attempt/10)"
    sleep 2
done

# 모델 다운로드
ollama pull "$MODEL"

echo "✅ 모델 준비 완료: $MODEL"
