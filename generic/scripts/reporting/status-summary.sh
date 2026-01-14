#!/bin/bash
set -euo pipefail

# Canonical macOS bzcli path
BZCLI_DEFAULT="/Applications/Backblaze.app/Contents/MacOS/bzcli"
BZCLI="${BZCLI_PATH:-$BZCLI_DEFAULT}"

# Fall back to PATH if canonical path is missing
if [[ ! -x "$BZCLI" ]]; then
  if command -v bzcli >/dev/null 2>&1; then
    BZCLI="$(command -v bzcli)"
  else
    echo "bzcli not found"
    exit 0
  fi
fi

VAL="$("$BZCLI" report -v /backup/status/summary 2>/dev/null \
  | tr -d '\r' \
  | sed -E 's/^[[:space:]]*\"?//; s/\"?[[:space:]]*$//')"

echo "${VAL:-Unknown}"