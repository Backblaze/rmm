#!/bin/bash
# Addigy Inventory: Backblaze - Installed
# Reports whether the Backblaze client appears to be installed.

find_bzcli() {
  # Canonical macOS Backblaze location
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Optional override for testing / non-standard installs
  if [[ -n "${BZCLI_PATH:-}" && -x "${BZCLI_PATH}" ]]; then
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

if find_bzcli >/dev/null 2>&1 || pgrep -x "bzserv" >/dev/null 2>&1; then
  echo "<result>Installed</result>"
else
  echo "<result>Not Installed</result>"
fi
