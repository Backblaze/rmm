#!/bin/bash
# Backblaze Health Score (Addigy)
#
# Output values (deterministic precedence):
#   NOT_INSTALLED -> bzcli binary not present
#   RED           -> paused/error/waiting states OR no/invalid last backup OR stale backup >= 7 days
#   YELLOW        -> last backup between 24 hours and < 7 days
#   GREEN         -> last backup <= 24 hours AND status indicates active/backing up
#
# Notes:
# - Addigy scripts run as root; bzcli may require a GUI user context on some systems.
# - This script is intentionally conservative: unknown/unexpected states default to RED.

set -u
set -o pipefail

result() { echo "<result>$1</result>"; exit 0; }

find_bzcli() {
  # Optional override for testing / non-standard installs
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

  # Minimal legacy/common fallbacks
  for p in "/usr/local/bin/bzcli" "/opt/homebrew/bin/bzcli" "/usr/bin/bzcli" "/Library/Backblaze/bzcli"; do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done

  return 1
}

# Thresholds
WARN_AFTER_HOURS=24
CRIT_AFTER_HOURS=$((24 * 7))

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_report_value() {
  local s
  s="$(printf '%s' "${1:-}" | tr -d '\r' | tail -n 1)"
  s="$(trim "$s")"
  s="${s#\"}"
  s="${s%\"}"
  printf '%s' "$s"
}

# Parse common ISO8601 formats to epoch seconds (macOS date)
# Accepts: 2026-02-19T11:55:00Z, 2026-02-19T11:55:00+00:00, 2026-02-19T11:55:00.123Z
iso8601_to_epoch() {
  local iso norm datepart timepart tzoff frac
  norm="$(trim "$1")"
  [[ -z "$norm" || "$norm" == "null" ]] && return 1

  if [[ "$norm" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[T\ ]([0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?(Z|([+-][0-9]{2}):?([0-9]{2}))?$ ]]; then
    datepart="${BASH_REMATCH[1]}"
    timepart="${BASH_REMATCH[2]}"

    if [[ -n "${BASH_REMATCH[4]}" ]]; then
      if [[ "${BASH_REMATCH[4]}" == "Z" ]]; then
        tzoff="+0000"
      else
        tzoff="${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
      fi
      /bin/date -j -f "%Y-%m-%dT%H:%M:%S%z" "${datepart}T${timepart}${tzoff}" "+%s" 2>/dev/null
      return $?
    fi

    /bin/date -j -f "%Y-%m-%dT%H:%M:%S" "${datepart}T${timepart}" "+%s" 2>/dev/null
    return $?
  fi

  return 1
}

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
      /bin/launchctl asuser "$uid" /usr/bin/sudo -u "$u" "$BZCLI" "$@" 2>/dev/null
      return $?
    fi
  fi
  "$BZCLI" "$@" 2>/dev/null
}

if ! BZCLI="$(find_bzcli)"; then
  result "NOT_INSTALLED"
fi

STATUS_RAW="$(run_bzcli report -v /backup/status/summary || true)"
STATUS_RAW="$(normalize_report_value "${STATUS_RAW:-}")"
STATUS_LC="$(lower "${STATUS_RAW:-unknown}")"

LAST_BACKUP_RAW="$(run_bzcli report -v /backup/lastbackup || true)"
LAST_BACKUP_RAW="$(normalize_report_value "${LAST_BACKUP_RAW:-}")"

if [[ -z "$LAST_BACKUP_RAW" || "$LAST_BACKUP_RAW" == "null" ]]; then
  result "RED"
fi

LAST_BACKUP_EPOCH="$(iso8601_to_epoch "$LAST_BACKUP_RAW" || true)"
if [[ -z "$LAST_BACKUP_EPOCH" ]]; then
  result "RED"
fi

NOW_EPOCH="$(date "+%s")"
HOURS_SINCE_BACKUP=$(( (NOW_EPOCH - LAST_BACKUP_EPOCH) / 3600 ))

if [[ "$HOURS_SINCE_BACKUP" -lt 0 ]]; then
  HOURS_SINCE_BACKUP=0
fi

case "$STATUS_LC" in
  *error*|*waiting*|*paused*|*pause*|*initial\ backup:*paused*)
    result "RED"
    ;;
esac

if [[ "$STATUS_LC" == *active* || "$STATUS_LC" == *backing*up* || "$STATUS_LC" == *backing\ up* ]]; then
  if [[ "$HOURS_SINCE_BACKUP" -le "$WARN_AFTER_HOURS" ]]; then
    result "GREEN"
  fi
fi

if [[ "$HOURS_SINCE_BACKUP" -gt "$WARN_AFTER_HOURS" && "$HOURS_SINCE_BACKUP" -lt "$CRIT_AFTER_HOURS" ]]; then
  result "YELLOW"
fi

if [[ "$HOURS_SINCE_BACKUP" -ge "$CRIT_AFTER_HOURS" ]]; then
  result "RED"
fi

result "RED"
