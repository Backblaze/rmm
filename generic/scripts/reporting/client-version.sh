#!/bin/bash
set -euo pipefail

# Generic bzcli reporting script: Client Version
# Outputs a single plain-text value.

get_bzcli() {
  local p
  # Preferred canonical path for macOS Desktop Client
  p="/Applications/Backblaze.app/Contents/MacOS/bzcli"
  if [[ -n "${BZCLI_PATH:-}" ]]; then
    p="$BZCLI_PATH"
  fi
  if [[ -x "$p" ]]; then
    echo "$p"
    return 0
  fi
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi
  return 1
}

if ! BZCLI="$(get_bzcli)"; then
  echo "bzcli not found"
  exit 0
fi

VAL="$($BZCLI report -v /backup/installation/version 2>/dev/null | tr -d '\r' | sed -E 's/^"//; s/"$//')"
echo "${VAL:-Unknown}"
