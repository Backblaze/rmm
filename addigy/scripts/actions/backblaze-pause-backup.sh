#!/bin/bash
# Backblaze - pause backup (Addigy)
# Pauses backup and logs normalized status before and after the action.
#
# Addigy notes:

set -euo pipefail

BZCLI="/Applications/Backblaze.app/Contents/MacOS/bzcli"
LOG_FILE="${LOG_FILE:-/var/log/backblaze_mdm_actions.log}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [bzcli][pause-backup] $*" | tee -a "$LOG_FILE"
}
die() {
  log "ERROR: $*"
  exit 1
}

[[ "$(id -u)" -eq 0 ]] || die "Must run as root."

if [[ -z "$BZCLI" ]]; then
  if ! BZCLI="$(find_bzcli)"; then
    die "bzcli not found."
  fi
fi

[[ -x "$BZCLI" ]] || die "bzcli not found/executable at: $BZCLI"

log "Checking status before pause..."
PRE_STATUS="$($BZCLI report -v /backup/status/summary 2>/dev/null | tail -n 1 || true)"
log "status_before=${PRE_STATUS:-unknown}"

log "Pausing backup..."
"$BZCLI" action --pause-backup >>"$LOG_FILE" 2>&1
RC=$?

log "Checking status after pause..."
POST_STATUS="$($BZCLI report -v /backup/status/summary 2>/dev/null | tail -n 1 || true)"
log "status_after=${POST_STATUS:-unknown}"

if [[ $RC -eq 0 ]]; then
  log "Pause backup action completed."
else
  log "ERROR: pause-backup failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
