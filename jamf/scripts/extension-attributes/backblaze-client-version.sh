#!/bin/bash
# Jamf Extension Attribute: Backblaze – Client Version
# Reports the installed Backblaze client version using bzcli

find_bzcli() {
  # Canonical macOS location for Backblaze bzcli
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Optional override for testing / non-standard installs
  if [[ -n "$BZCLI_PATH" && -x "$BZCLI_PATH" ]]; then
    echo "$BZCLI_PATH"
    return 0
  fi

  # Fallback to PATH (unlikely but safe)
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

VAL="$($BZCLI report -v /backup/installation/version 2>/dev/null | tr -d '\r')"
echo "<result>${VAL:-Unknown}</result>"
