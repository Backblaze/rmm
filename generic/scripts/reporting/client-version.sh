#!/bin/bash
set -euo pipefail

BZCLI="/Applications/Backblaze.app/Contents/MacOS/bzcli"
if [[ -n "${BZCLI_PATH:-}" ]]; then BZCLI="$BZCLI_PATH"; fi
if [[ ! -x "$BZCLI" ]]; then
  if command -v bzcli >/dev/null 2>&1; then
    BZCLI="$(command -v bzcli)"
  else
    echo "bzcli not found"
    exit 0
  fi
fi

VAL="$("$BZCLI" report -v /backup/installation/version 2>/dev/null | tr -d '\r')"
echo "${VAL:-Unknown}"
