#!/bin/bash
# Backblaze - client version (Addigy inventory)
# Reports the installed Backblaze client version using bzcli.

set -euo pipefail

find_bzcli() {
  # Prefer canonical macOS location for Backblaze bzcli
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Optional override for testing or non-standard installs
  if [[ -n "${BZCLI_PATH:-}" && -x "${BZCLI_PATH}" ]]; then
    echo "${BZCLI_PATH}"
    return 0
  fi

  # Fallback to PATH
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  return 1
}

normalize_value() {
  local v
  v="${1:-}"
  v="$(printf '%s' "$v" | head -n 1 | tr -d '\r' | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//')"
  if [[ -z "$v" ]]; then
    echo "Unknown"
  else
    echo "$v"
  fi
}

if ! BZCLI="$(find_bzcli)"; then
  echo "<result>bzcli not found</result>"
  exit 0
fi

VAL_RAW="$("$BZCLI" report -v /backup/installation/version 2>/dev/null || true)"
VAL="$(normalize_value "$VAL_RAW")"
echo "<result>${VAL}</result>"
