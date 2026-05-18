#!/bin/bash
# Backblaze - bzcli action: backup Now (with status check)
#
# Addigy notes:
# - Runs as root.
# - No parameters are required.
# - Optional: set BZCLI_PATH env var to override bzcli path.
# - Uses --backup-now as the effective resume action for this bzcli build.

set -euo pipefail

log() {
  # Write to log file and stderr (keep stdout clean for command output capture)
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [resume-backup] $*"
  echo "$msg" | tee -a "$LOG" >&2
}

run_bzcli() {
  # Usage: run_bzcli <args...>
  run_as_console_user "$CONSOLE_USER" "$BZCLI" "$@"
}

bzcli_report_summary() {
  # Returns a single-line backup status summary (or 'unknown').
  local out
  out="$(run_bzcli report -v /backup/status/summary 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  echo "${out:-unknown}"
}

LOG="/var/log/backblaze_bzcli_action.log"

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

CONSOLE_USER="$(get_console_user)"

PRE_STATUS="$(bzcli_report_summary)"
log "Status BEFORE: \"$PRE_STATUS\""

set +e
# This bzcli build does not support --resume-backup. "Resume" is effectively achieved by starting a backup.
# If the client is paused, --backup-now transitions it back into an active backup.
run_bzcli action --backup-now >>"$LOG" 2>&1
RC=$?
set -e

POST_STATUS="$(bzcli_report_summary)"
log "Status AFTER: \"$POST_STATUS\""

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: resume requested via --backup-now."
else
  log "ERROR: resume request failed via --backup-now with exit code $RC."
  log "Next steps: check $LOG for the full bzcli output; verify Backblaze is signed in and bzserv is running."
fi
