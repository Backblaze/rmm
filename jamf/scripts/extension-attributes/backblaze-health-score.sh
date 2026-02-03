#!/bin/bash
# Backblaze Health Score – V1 (Jamf Extension Attribute)
# Returns: Healthy | Warning | Critical | Not Installed

set -euo pipefail

BZCLI="/Applications/Backblaze.app/Contents/MacOS/bzcli"

result() { echo "<result>$1</result>"; exit 0; }

get_console_user() {
  local u
  u="$(stat -f%Su /dev/console 2>/dev/null || true)"
  if [[ -z "$u" || "$u" == "root" || "$u" == "loginwindow" || "$u" == "_mbsetupuser" ]]; then
    echo ""
  else
    echo "$u"
  fi
}

run_bzcli() {
  local u uid
  u="$(get_console_user)"
  if [[ -n "$u" ]]; then
    uid="$(id -u "$u" 2>/dev/null || true)"
    if [[ -n "$uid" ]]; then
      /bin/launchctl asuser "$uid" /usr/bin/sudo -u "$u" "$BZCLI" "$@"
      return
    fi
  fi
  "$BZCLI" "$@"
}

# Not installed
if [[ ! -x "$BZCLI" ]]; then
  result "Not Installed"
fi

STATUS="$(run_bzcli report -v /backup/status/summary 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
STATUS="${STATUS:-unknown}"

LAST_BACKUP="$(run_bzcli report -v /backup/lastbackup 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
LAST_BACKUP="${LAST_BACKUP:-}"

shopt -s nocasematch
if [[ -z "$LAST_BACKUP" || "$LAST_BACKUP" == "null" ]]; then
  result "Critical"
fi
shopt -u nocasematch

NORM="${LAST_BACKUP/T/ }"
NORM="${NORM:0:19}"

LAST_BACKUP_EPOCH="$(date -j -f "%Y-%m-%d %H:%M:%S" "$NORM" "+%s" 2>/dev/null || true)"
if [[ -z "$LAST_BACKUP_EPOCH" ]]; then
  result "Critical"
fi

NOW_EPOCH="$(date "+%s")"
HOURS_SINCE_BACKUP=$(( (NOW_EPOCH - LAST_BACKUP_EPOCH) / 3600 ))

case "$STATUS" in
  *Error*|*ERROR*|*Waiting*|*Paused*|*pause*|*Initial\ backup:\ Paused*)
    result "Critical"
    ;;
esac

if [[ "$STATUS" == *Active* || "$STATUS" == *Backing\ up* || "$STATUS" == *Backing*up* ]]; then
  if [[ "$HOURS_SINCE_BACKUP" -le 24 ]]; then
    result "Healthy"
  fi
fi

if [[ "$HOURS_SINCE_BACKUP" -gt 24 && "$HOURS_SINCE_BACKUP" -lt 168 ]]; then
  result "Warning"
fi

result "Critical"
