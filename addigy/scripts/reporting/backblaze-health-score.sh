#!/bin/bash
# Backblaze Health Score – V1 (Jamf Extension Attribute)
#
# Output values (deterministic precedence):
#   NOT_INSTALLED -> bzcli binary not present
#   RED           -> paused/error/waiting states OR no/invalid last backup OR stale backup >= 7 days
#   YELLOW        -> last backup between 24 hours and < 7 days
#   GREEN         -> last backup <= 24 hours AND status indicates active/backing up
#
# Notes:
# - Jamf EAs run as root; bzcli may require a GUI user context on some systems.
# - This EA is intentionally conservative: unknown/unexpected states default to Critical.

set -u
set -o pipefail

BZCLI="/Applications/Backblaze.app/Contents/MacOS/bzcli"

result() { echo "<result>$1</result>"; exit 0; }

# Thresholds
WARN_AFTER_HOURS=24
CRIT_AFTER_HOURS=$((24 * 7))

trim() {
  # trim leading/trailing whitespace
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Parse common ISO8601 formats to epoch seconds (macOS date)
# Accepts: 2026-02-19T11:55:00Z, 2026-02-19T11:55:00+00:00, 2026-02-19T11:55:00.123Z
iso8601_to_epoch() {
  local iso norm datepart timepart tzoff frac
  norm="$(trim "$1")"
  [[ -z "$norm" || "$norm" == "null" ]] && return 1

  # Match: YYYY-MM-DDTHH:MM:SS(.sss)?(Z|+HH:MM|-HH:MM)?
  if [[ "$norm" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})[T\ ]([0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?(Z|([+-][0-9]{2}):?([0-9]{2}))?$ ]]; then
    datepart="${BASH_REMATCH[1]}"
    timepart="${BASH_REMATCH[2]}"

    # Time zone handling
    if [[ -n "${BASH_REMATCH[4]}" ]]; then
      if [[ "${BASH_REMATCH[4]}" == "Z" ]]; then
        tzoff="+0000"
      else
        tzoff="${BASH_REMATCH[5]}${BASH_REMATCH[6]}"  # +HHMM or -HHMM
      fi
      /bin/date -j -f "%Y-%m-%dT%H:%M:%S%z" "${datepart}T${timepart}${tzoff}" "+%s" 2>/dev/null
      return $?
    fi

    # No TZ provided: interpret as local time
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
      /bin/launchctl asuser "$uid" "$BZCLI" "$@" 2>/dev/null
      return 0
    fi
  fi
  "$BZCLI" "$@" 2>/dev/null
}

# Not installed
if [[ ! -x "$BZCLI" ]]; then
  result "NOT_INSTALLED"
fi

STATUS_RAW="$(run_bzcli report -v /backup/status/summary | tr -d '\r' | tail -n 1 || true)"
STATUS_RAW="$(trim "${STATUS_RAW:-}")"
STATUS_LC="$(lower "${STATUS_RAW:-unknown}")"

LAST_BACKUP_RAW="$(run_bzcli report -v /backup/lastbackup | tr -d '\r' | tail -n 1 || true)"
LAST_BACKUP_RAW="$(trim "${LAST_BACKUP_RAW:-}")"

# If no last backup timestamp, treat as RED
if [[ -z "$LAST_BACKUP_RAW" || "$LAST_BACKUP_RAW" == "null" ]]; then
  result "RED"
fi

LAST_BACKUP_EPOCH="$(iso8601_to_epoch "$LAST_BACKUP_RAW" || true)"
if [[ -z "$LAST_BACKUP_EPOCH" ]]; then
  result "RED"
fi

NOW_EPOCH="$(date "+%s")"
HOURS_SINCE_BACKUP=$(( (NOW_EPOCH - LAST_BACKUP_EPOCH) / 3600 ))

# If the timestamp is in the future (clock skew), treat as fresh
if [[ "$HOURS_SINCE_BACKUP" -lt 0 ]]; then
  HOURS_SINCE_BACKUP=0
fi

case "$STATUS_LC" in
  *error*|*waiting*|*paused*|*pause*|*initial\ backup:*paused*)
    result "RED"
    ;;
esac

# If actively backing up, and last backup is fresh, mark GREEN.
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
