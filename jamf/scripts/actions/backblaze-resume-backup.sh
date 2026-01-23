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
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [resume-backup] $*"
  # Write to log file and stderr (keep stdout clean for command output capture)
  echo "$msg" | tee -a "$LOG" >&2
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

get_console_user() {
  # Return the current GUI console user (empty if none)
  local u
  u="$(stat -f%Su /dev/console 2>/dev/null || true)"
  # Filter out system pseudo-users
  if [[ -z "$u" || "$u" == "root" || "$u" == "_mbsetupuser" || "$u" == "loginwindow" ]]; then
    echo ""
  else
    echo "$u"
  fi
}

run_bzcli() {
  # Run bzcli as the console user when available (needed for some actions like resume/pause)
  local console_user uid
  console_user="$(get_console_user)"

  if [[ -n "$console_user" ]]; then
    uid="$(id -u "$console_user" 2>/dev/null || true)"
    if [[ -n "$uid" ]]; then
      log "Running bzcli as console user '$console_user' (uid=$uid)"
      /bin/launchctl asuser "$uid" /usr/bin/sudo -u "$console_user" "$BZCLI" "$@"
      return $?
    fi
  fi

  log "Running bzcli as root (no valid console user detected)"
  "$BZCLI" "$@"
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

PRE_STATUS="$(run_bzcli report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status BEFORE: ${PRE_STATUS:-unknown}"

set +e
# This bzcli build does not support --resume-backup. "Resume" is effectively achieved by starting a backup.
# If the client is paused, --backup-now transitions it back into an active backup.
run_bzcli action --backup-now >>"$LOG" 2>&1
RC=$?
set -e

# Show last lines in Jamf policy output for quick debugging
# IMPORTANT: Do NOT append the tail back into the same log file (it causes duplicated/recursive log lines).
log "bzcli action output (tail):"
/usr/bin/tail -n 25 "$LOG" >&2

POST_STATUS="$(run_bzcli report -v /backup/status/summary 2>/dev/null | tr -d '\r' || echo unknown)"
log "Status AFTER: ${POST_STATUS:-unknown}"

if [[ $RC -eq 0 ]]; then
  log "SUCCESS: resume requested (via --backup-now)."
else
  log "ERROR: resume request failed (via --backup-now) with exit code $RC."
  log "Next steps: check $LOG for the full bzcli output; verify Backblaze is signed in and bzserv is running."
fi

log "=== END (rc=$RC) ==="
exit "$RC"
