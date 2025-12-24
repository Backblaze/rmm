#!/bin/bash
# Backblaze - bzcli action: resume backup (with status check)

set -u

LOG="/var/log/backblaze_bzcli_action.log"
BZCLI_DEFAULT="/usr/local/bin/bzcli"
BZCLI="${4:-$BZCLI_DEFAULT}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [resume-backup] $*" | tee -a "$LOG"; }

log "=== START ==="
log "Using bzcli: $BZCLI"

if [[ $EUID -ne 0 ]]; then
  log "ERROR: must run as root."
  exit 1
fi

if [[ ! -x "$BZCLI" ]]; then
  log "ERROR: bzcli not found at '$BZCLI'."
  exit 2
fi

PRE_STATUS="$("$BZCLI" report -v /backup/status/summary 2>/dev/null || echo unknown)"
log "Status BEFORE: $PRE_STATUS"

"$BZCLI" action --resume-backup >>"$LOG" 2>&1
RC=$?

POST_STATUS="$("$BZCLI" report -v /backup/status/summary 2>/dev/null || echo unknown)"
log "Status AFTER: $POST_STATUS"

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: resume-backup command executed."
else
  log "ERROR: resume-backup failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
