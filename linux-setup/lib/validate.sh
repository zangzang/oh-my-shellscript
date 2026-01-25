#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

fail=0

log() { echo "[validate] $*"; }
err() { echo "[validate][ERROR] $*"; fail=1; }

if ! command -v jq >/dev/null 2>&1; then
  err "jq is required. Please install it first."
  exit 1
fi

log "Validating module metadata..."
declare -A module_paths

while IFS= read -r meta; do
  if ! jq -e . >/dev/null 2>&1 <"$meta"; then
    err "Invalid JSON: $meta"
    continue
  fi

  id=$(jq -r '.id // empty' "$meta")
  name=$(jq -r '.name // empty' "$meta")

  if [[ -z "$id" ]]; then
    err "Missing 'id': $meta"
    continue
  fi
  if [[ -z "$name" ]]; then
    err "Missing 'name': $meta"
  fi

  if [[ -n "${module_paths[$id]:-}" ]]; then
    err "Duplicate module id '$id': ${module_paths[$id]} AND $meta"
  else
    module_paths[$id]="$(dirname "$meta")"
  fi

  # Check variants type
  if jq -e 'has("variants") and (.variants|type!="array")' >/dev/null 2>&1 <"$meta"; then
    err "'variants' must be an array: $meta"
  fi

done < <(find "$SCRIPT_DIR/modules" -name meta.json | sort)

log "Checking module scripts existence/permissions..."
for id in "${!module_paths[@]}"; do
  p="${module_paths[$id]}"
  if [[ ! -f "$p/install.sh" ]]; then
    err "Missing install.sh: $id ($p)"
  elif [[ ! -x "$p/install.sh" ]]; then
    err "install.sh not executable: $id ($p/install.sh)"
  fi

done

log "Validating presets..."
while IFS= read -r preset; do
  if ! jq -e . >/dev/null 2>&1 <"$preset"; then
    err "Invalid JSON: $preset"
    continue
  fi

  # modules must be an array
  if ! jq -e '.modules|type=="array"' >/dev/null 2>&1 <"$preset"; then
    err "'modules' array missing or invalid format: $preset"
    continue
  fi

  while IFS= read -r entry; do
    mid=$(jq -r '.id // empty' <<<"$entry")
    ver=$(jq -r '.params.version // empty' <<<"$entry")

    if [[ -z "$mid" ]]; then
      err "Missing item id in preset: $preset"
      continue
    fi

    if [[ -z "${module_paths[$mid]:-}" ]]; then
      err "Non-existent module id '$mid' (preset: $preset)"
      continue
    fi

    if [[ -n "$ver" ]]; then
      meta_path="${module_paths[$mid]}/meta.json"
      if jq -e 'has("variants")' >/dev/null 2>&1 <"$meta_path"; then
        if ! jq -e --arg v "$ver" '(.variants // []) | index($v) != null' >/dev/null 2>&1 <"$meta_path"; then
          err "Preset version '$ver' not in variants: $mid (preset: $preset)"
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