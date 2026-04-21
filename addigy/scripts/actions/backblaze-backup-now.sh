#!/bin/bash
# Backblaze - bzcli action: backup now (with status check)
#
# Jamf Pro notes:
# - Jamf runs scripts as root.
# - No parameters are required.
# - Optional: set BZCLI_PATH env var to override bzcli path.
# - Runs bzcli as the active console user (required for some UI-bound operations).

set -euo pipefail

get_console_user() {
  # Returns the logged-in GUI user, or empty if none.
  local u
  u="$(stat -f%Su /dev/console 2>/dev/null || true)"
  if [[ -z "$u" || "$u" == "root" ]]; then
    echo ""
  else
    echo "$u"
  fi
}

run_as_console_user() {
  # Runs the given command as the console user when possible.
  # Usage: run_as_console_user <user> <cmd> [args...]
  local u="$1"; shift

  if [[ -z "$u" ]]; then
    "$@"
    return $?
  fi

  local uid
  uid="$(id -u "$u" 2>/dev/null || true)"
  if [[ -z "$uid" ]]; then
    "$@"
    return $?
  fi

  if command -v launchctl >/dev/null 2>&1; then
    launchctl asuser "$uid" sudo -u "$u" "$@"
  else
    sudo -u "$u" "$@"
  fi
}

LOG="/var/log/backblaze_bzcli_action.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [backup-now] $*" | tee -a "$LOG"
}

run_bzcli() {
  # Usage: run_bzcli <console_user> <bzcli_path> <args...>
  local u="$1"; shift
  local bz="$1"; shift

  # Send bzcli stdout/stderr to the shared log; return bzcli exit code.
  run_as_console_user "$u" "$bz" "$@" >>"$LOG" 2>&1
  return $?
}

bzcli_report_summary() {
  # Returns a single-line backup status summary (or 'unknown').
  local u="$1"
  local bz="$2"

  local out
  out="$(run_as_console_user "$u" "$bz" report -v /backup/status/summary 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  echo "${out:-unknown}"
}

find_bzcli() {
  # Canonical Backblaze Desktop client location on macOS
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Fallback: PATH
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  # Fallback: common package manager / legacy locations
  for p in "/usr/local/bin/bzcli" "/opt/homebrew/bin/bzcli" "/usr/bin/bzcli" "/Library/Backblaze/bzcli"; do
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

CONSOLE_USER="$(get_console_user)"
if [[ -n "$CONSOLE_USER" ]]; then
  log "Running bzcli as console user '$CONSOLE_USER'"
else
  log "WARN: No console user detected; running bzcli as root."
fi

PRE_STATUS="$(bzcli_report_summary "$CONSOLE_USER" "$BZCLI")"
log "Status BEFORE: \"$PRE_STATUS\""

# Execute action
set +e
run_bzcli "$CONSOLE_USER" "$BZCLI" action --backup-now
RC=$?
set -e

POST_STATUS="$(bzcli_report_summary "$CONSOLE_USER" "$BZCLI")"
log "Status AFTER: \"$POST_STATUS\""

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: backup-now command executed."
else
  log "ERROR: backup-now failed with exit code $RC."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
