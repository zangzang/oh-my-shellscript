#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

fail=0

log() { echo "[validate] $*"; }
err() { echo "[validate][ERROR] $*"; fail=1; }

if ! command -v jq >/dev/null 2>&1; then
  err "jq가 필요합니다. 먼저 설치하세요."
  exit 1
fi

log "모듈 메타데이터 검증 중..."
declare -A module_paths

while IFS= read -r meta; do
  if ! jq -e . >/dev/null 2>&1 <"$meta"; then
    err "유효하지 않은 JSON: $meta"
    continue
  fi

  id=$(jq -r '.id // empty' "$meta")
  name=$(jq -r '.name // empty' "$meta")

  if [[ -z "$id" ]]; then
    err "id 누락: $meta"
    continue
  fi
  if [[ -z "$name" ]]; then
    err "name 누락: $meta"
  fi

  if [[ -n "${module_paths[$id]:-}" ]]; then
    err "중복 모듈 id '$id': ${module_paths[$id]} AND $meta"
  else
    module_paths[$id]="$(dirname "$meta")"
  fi

  # variants 타입 체크
  if jq -e 'has("variants") and (.variants|type!="array")' >/dev/null 2>&1 <"$meta"; then
    err "variants는 배열이어야 합니다: $meta"
  fi

done < <(find "$SCRIPT_DIR/modules" -name meta.json | sort)

log "모듈 스크립트 존재/권한 확인 중..."
for id in "${!module_paths[@]}"; do
  p="${module_paths[$id]}"
  if [[ ! -f "$p/install.sh" ]]; then
    err "install.sh 누락: $id ($p)"
  elif [[ ! -x "$p/install.sh" ]]; then
    err "install.sh 실행권한 없음: $id ($p/install.sh)"
  fi

done

log "프리셋 검증 중..."
while IFS= read -r preset; do
  if ! jq -e . >/dev/null 2>&1 <"$preset"; then
    err "유효하지 않은 JSON: $preset"
    continue
  fi

  # modules는 배열이어야 함
  if ! jq -e '.modules|type=="array"' >/dev/null 2>&1 <"$preset"; then
    err "modules 배열 누락/형식 오류: $preset"
    continue
  fi

  while IFS= read -r entry; do
    mid=$(jq -r '.id // empty' <<<"$entry")
    ver=$(jq -r '.params.version // empty' <<<"$entry")

    if [[ -z "$mid" ]]; then
      err "preset 항목 id 누락: $preset"
      continue
    fi

    if [[ -z "${module_paths[$mid]:-}" ]]; then
      err "존재하지 않는 모듈 id '$mid' (preset: $preset)"
      continue
    fi

    if [[ -n "$ver" ]]; then
      meta_path="${module_paths[$mid]}/meta.json"
      if jq -e 'has("variants")' >/dev/null 2>&1 <"$meta_path"; then
        if ! jq -e --arg v "$ver" '(.variants // []) | index($v) != null' >/dev/null 2>&1 <"$meta_path"; then
          err "preset 버전 '$ver'가 variants에 없음: $mid (preset: $preset)"
        fi
      fi
    fi
  done < <(jq -c '.modules[]' "$preset")

done < <(find "$SCRIPT_DIR/presets" -maxdepth 1 -name "*.json" | sort)

if [[ $fail -eq 0 ]]; then
  log "OK"
  exit 0
fi

log "FAIL"
exit 1
