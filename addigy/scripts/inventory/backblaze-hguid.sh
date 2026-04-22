#!/bin/bash
# Addigy Inventory: Backblaze - HGUID
# Reports the installed Backblaze HGUID using bzcli

find_bzcli() {
  # Canonical macOS Backblaze location
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Optional override for testing / non-standard installs
  if [[ -n "${BZCLI_PATH:-}" && -x "${BZCLI_PATH:-}" ]]; then
    echo "${BZCLI_PATH}"
    return 0
  fi

  # PATH fallback
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  return 1
}

if ! BZCLI="$(find_bzcli)"; then
  echo "<result>bzcli not found</result>"
  exit 0
fi

VAL="$($BZCLI report -v /backup/installation/hguid 2>/dev/null | tr -d '\r' | tail -n 1)"
VAL="${VAL:-Unknown}"
echo "<result>${VAL}</result>"
