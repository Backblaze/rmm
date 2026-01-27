#!/bin/bash
# Backblaze Desktop Client (macOS) - Generic Action Script
# Action: Resume backups (via bzcli)
# Requirements: Backblaze Desktop Client installed (bzcli present).

set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/backblaze_bzcli_actions.log}"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][resume-backup] $*"
  if ! { touch "$LOG_FILE" 2>/dev/null; }; then
    LOG_FILE="/tmp/backblaze_bzcli_actions.log"
  fi
  echo "$msg" | tee -a "$LOG_FILE"
}

find_bzcli() {
  local canonical="/Applications/Backblaze.app/Contents/MacOS/bzcli"
  if [[ -x "$canonical" ]]; then
    echo "$canonical"
    return 0
  fi
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi
  return 1
}

log "=== START ==="

if [[ ${EUID} -ne 0 ]]; then
  log "WARN: not running as root. Some actions may fail depending on local configuration."
fi

BZCLI="${BZCLI_PATH:-""}"
if [[ -z "$BZCLI" ]]; then
  if ! BZCLI="$(find_bzcli)"; then
    log "ERROR: bzcli not found. Expected at /Applications/Backblaze.app/Contents/MacOS/bzcli or in PATH."
    exit 2
  fi
fi

if [[ ! -x "$BZCLI" ]]; then
  log "ERROR: bzcli is not executable at '$BZCLI'."
  exit 2
fi

log "Using bzcli: $BZCLI"

PRE_STATUS_RAW="$($BZCLI report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status BEFORE: ${PRE_STATUS_RAW:-unknown}"

# If not paused, treat as a no-op success (safe for automation).
if [[ "$PRE_STATUS_RAW" != *Paused* && "$PRE_STATUS_RAW" != *paused* ]]; then
  log "INFO: Backups are not paused; nothing to resume."
  log "=== END (rc=0) ==="
  exit 0
fi

set +e
"$BZCLI" action --resume-backup >>"$LOG_FILE" 2>&1
RC=$?
set -e

POST_STATUS="$($BZCLI report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status AFTER: ${POST_STATUS:-unknown}"

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: resume-backup executed."
else
  log "ERROR: resume-backup failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
