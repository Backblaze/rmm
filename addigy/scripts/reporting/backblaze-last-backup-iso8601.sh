#!/bin/bash
# Addigy Custom Fact: Backblaze - Last Backup (ISO8601)
# Reports the most recent Backblaze backup timestamp normalized to ISO8601.

find_bzcli() {
  # Canonical macOS Backblaze location
  if [[ -x "/Applications/Backblaze.app/Contents/MacOS/bzcli" ]]; then
    echo "/Applications/Backblaze.app/Contents/MacOS/bzcli"
    return 0
  fi

  # Optional override for testing / non-standard installs
  if [[ -n "${BZCLI_PATH:-}" && -x "${BZCLI_PATH}" ]]; then
    echo "${BZCLI_PATH}"
    return 0
  fi

  # PATH fallback
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi

  return 1
}

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

normalize_last_backup() {
  local raw val
  raw="$1"
  val="$(printf '%s' "$raw" | tr -d '\r' | tail -n 1)"
  val="$(trim "$val")"

  # Remove surrounding double quotes if present.
  val="${val#\"}"
  val="${val%\"}"

  if [[ -z "$val" || "$val" == "null" ]]; then
    printf '%s' "Never"
    return 0
  fi

  # Convert `YYYY-MM-DD HH:MM:SS` to ISO8601 `YYYY-MM-DDTHH:MM:SS`.
  if [[ "$val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    val="${val/ /T}"
  fi

  printf '%s' "$val"
}

if ! BZCLI="$(find_bzcli)"; then
  echo "<result>bzcli not found</result>"
  exit 0
fi

RAW_VAL="$($BZCLI report -v /backup/status/last_backup/ISO8601 2>/dev/null || true)"
VAL="$(normalize_last_backup "$RAW_VAL")"
echo "<result>${VAL}</result>"
