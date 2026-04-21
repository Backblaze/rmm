#!/bin/bash
# Backblaze - bzcli action: pause backup (with status check)
#
# Addigy notes:
# - Runs as root.
# - No parameters are required.
# - Optional: set BZCLI_PATH env var to override bzcli path.

set -euo pipefail

LOG="/var/log/backblaze_bzcli_action.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [pause-backup] $*" | tee -a "$LOG"
}

find_bzcli() {
  # Prefer canonical macOS Backblaze path
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Fallback to PATH
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  return 1
}

normalize_status() {
  # bzcli report output often comes wrapped in quotes; normalize for clean logs
  local s
  s="${1:-unknown}"
  # take first line only, strip CR, trim surrounding quotes and whitespace
  s="$(printf '%s' "$s" | head -n 1 | tr -d '\r' | sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//')"
  if [[ -z "$s" ]]; then
    echo "unknown"
  else
    echo "$s"
  fi
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

PRE_STATUS_RAW="$($BZCLI report -v /backup/status/summary 2>/dev/null || echo unknown)"
PRE_STATUS="$(normalize_status "$PRE_STATUS_RAW")"
log "Status BEFORE: \"$PRE_STATUS\""

# Execute action
set +e
"$BZCLI" action --pause-backup >>"$LOG" 2>&1
RC=$?
set -e

POST_STATUS_RAW="$($BZCLI report -v /backup/status/summary 2>/dev/null || echo unknown)"
POST_STATUS="$(normalize_status "$POST_STATUS_RAW")"
log "Status AFTER: \"$POST_STATUS\""

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: pause-backup command executed."
else
  log "ERROR: pause-backup failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
