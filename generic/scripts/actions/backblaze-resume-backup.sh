#!/bin/bash
# Backblaze - bzcli action: resume backup (with status check)
#
# Jamf Pro notes:
# - Jamf runs scripts as root.
# - No parameters are required.
# - Optional: set BZCLI_PATH env var to override bzcli path.

set -euo pipefail

LOG="/var/log/backblaze_bzcli_action.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [resume-backup] $*" | tee -a "$LOG"
}

find_bzcli() {
  # Optional explicit override
  if [[ -n "${BZCLI_PATH:-}" && -x "${BZCLI_PATH}" ]]; then
    echo "${BZCLI_PATH}"
    return 0
  fi

  # Canonical macOS Backblaze location
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # PATH fallback
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  # Minimal legacy fallbacks
  for p in "/usr/local/bin/bzcli" "/opt/homebrew/bin/bzcli" "/usr/bin/bzcli"; do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done

  return 1
}

log "=== START ==="

if [[ ${EUID} -ne 0 ]]; then
  log "ERROR: must run as root."
  exit 1
fi

BZCLI="${BZCLI_PATH:-""}"
if [[ -z "$BZCLI" ]]; then
  if ! BZCLI="$(find_bzcli)"; then
    log "ERROR: bzcli not found."
    exit 2
  fi
fi

if [[ ! -x "$BZCLI" ]]; then
  log "ERROR: bzcli is not executable at '$BZCLI'."
  exit 2
fi

log "Using bzcli: $BZCLI"

PRE_STATUS="$($BZCLI report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status BEFORE: ${PRE_STATUS:-unknown}"

set +e
"$BZCLI" action --resume-backup >>"$LOG" 2>&1
RC=$?
set -e

POST_STATUS="$($BZCLI report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status AFTER: ${POST_STATUS:-unknown}"

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: resume-backup command executed."
else
  log "ERROR: resume-backup failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
