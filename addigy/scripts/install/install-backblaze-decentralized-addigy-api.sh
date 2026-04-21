#!/bin/bash
# Backblaze Business Group Install (Addigy) — API variant
#
# Purpose:
#   Installer that enrolls/signs-in devices to a Backblaze Business Group.
#   This Addigy-focused variant supports either:
#     - an explicit email override for controlled testing, or
#     - API-based email lookup using MDM inventory data.
#
# Script Parameters:
#   $4 = Backblaze Group ID            (required)
#   $5 = Backblaze Group Auth Token    (required)
#   $6 = Backblaze Email override      (optional; explicit email for controlled testing)
#   $7 = Backblaze Region              (optional)
#   $8 = MDM API URL                   (optional; required for API-based email lookup)
#   $9 = MDM API Client ID             (optional; required for API-based email lookup)
#   $10 = MDM API Client Secret        (optional; required for API-based email lookup)
#   $11 = Start backup after install   (optional; 1/true/yes to enable)
#
# Defaults:
#   - Uses the public v10 installer DMG by default
#   - Installs or silently upgrades if already installed
#   - Verifies bzserv is running (retry loop)
#
# Notes:
# - Runs as root from the MDM agent.
# - Logs to stdout + /var/log/backblaze_mdm_decentralized_addigy_api.log
# - Mirrors the RMM support log to /Library/Logs/BackblazeSilentInstaller/rmm.log
# - Does NOT print tokens.

set -euo pipefail

#############################################
# LOGGING
#############################################
LOG_FILE="/var/log/backblaze_mdm_decentralized_addigy_api.log"
RMM_LOG_DIR="/Library/Logs/BackblazeSilentInstaller"
RMM_LOG_FILE="${RMM_LOG_DIR}/rmm.log"
mkdir -p "$RMM_LOG_DIR"
touch "$LOG_FILE" "$RMM_LOG_FILE"
chmod 644 "$LOG_FILE" "$RMM_LOG_FILE" 2>/dev/null || true
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
exec > >(tee -a "$LOG_FILE" "$RMM_LOG_FILE") 2>&1

log "=== Backblaze Business Group install started (Addigy API variant) ==="

#############################################
# REQUIRE ROOT
#############################################
if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: Script must run as root."
  exit 1
fi

#############################################
# INPUTS
#############################################
BZ_GROUP_ID="${BZ_GROUP_ID:-""}"
BZ_GROUP_TOKEN="${BZ_GROUP_TOKEN:-""}"
BZ_EMAIL="${BZ_EMAIL:-""}"
BZ_REGION="${BZ_REGION:-""}"
BZ_START_BACKUP="${BZ_START_BACKUP:-""}"
MDM_API_URL="${MDM_API_URL:-""}"
MDM_API_CLIENT_ID="${MDM_API_CLIENT_ID:-""}"
MDM_API_CLIENT_SECRET="${MDM_API_CLIENT_SECRET:-""}"
ADDIGY_USER_NAME="${3-}"

# Default: public v10 installer DMG
BZ_DMG_URL_DEFAULT="https://secure.backblaze.com/mac/install_backblaze.dmg"
BZ_DMG_URL="${BZ_DMG_URL:-$BZ_DMG_URL_DEFAULT}"

#############################################
# ADDIGY PARAMETERS OVERRIDE
#############################################
# Addigy passes: $1 mountPoint, $2 computerName, $3 userName, $4+ custom
if [[ -n "${4-}" ]]; then BZ_GROUP_ID="$4"; fi
if [[ -n "${5-}" ]]; then BZ_GROUP_TOKEN="$5"; fi
if [[ -n "${6-}" ]]; then BZ_EMAIL="$6"; fi
if [[ -n "${7-}" ]]; then BZ_REGION="$7"; fi
if [[ -n "${8-}" ]]; then MDM_API_URL="$8"; fi
if [[ -n "${9-}" ]]; then MDM_API_CLIENT_ID="$9"; fi
if [[ -n "${10-}" ]]; then MDM_API_CLIENT_SECRET="${10}"; fi
if [[ -n "${11-}" ]]; then BZ_START_BACKUP="$11"; fi

#############################################
# EMAIL RESOLUTION (MDM API)
#############################################
CURRENT_USER="$(stat -f%Su /dev/console 2>/dev/null || true)"
EMAIL_SOURCE=""
MDM_API_TOKEN=""
MDM_API_EMAIL=""
SERIAL_NUMBER="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Serial Number/{print $2; exit}')"

# Use native macOS tools for JSON parsing so the script does not depend on
# Python 3 / Xcode Command Line Tools being present on newly enrolled Macs.

# Basic normalization in case the values include accidental whitespace.
BZ_EMAIL="$(printf '%s' "$BZ_EMAIL" | tr -d '[:space:]')"
MDM_API_URL="$(printf '%s' "$MDM_API_URL" | sed 's:/*$::')"

# Prefer explicit email override for controlled testing.
if [[ -n "${BZ_EMAIL:-}" ]]; then
  EMAIL_SOURCE="explicit override"
else
  # Primary path: look up the assigned user email in MDM inventory via API.
  if [[ -n "${MDM_API_URL:-}" && -n "${MDM_API_CLIENT_ID:-}" && -n "${MDM_API_CLIENT_SECRET:-}" && -n "${SERIAL_NUMBER:-}" ]]; then
    log "Attempting MDM API email lookup for serial ${SERIAL_NUMBER}."

    set +e
    MDM_API_TOKEN="$(
      curl -s --connect-timeout 15 --max-time 60 -X POST "${MDM_API_URL}/api/v1/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_id=${MDM_API_CLIENT_ID}" \
        --data-urlencode "client_secret=${MDM_API_CLIENT_SECRET}" | \
      /usr/bin/plutil -extract access_token raw -o - - 2>/dev/null
    )"
    TOKEN_RC=$?
    set -e

    if [[ $TOKEN_RC -eq 0 && -n "${MDM_API_TOKEN:-}" ]]; then
      set +e
      MDM_API_EMAIL="$(
        curl -sG --connect-timeout 15 --max-time 60 "${MDM_API_URL}/api/v1/computers-inventory" \
          -H "Authorization: Bearer ${MDM_API_TOKEN}" \
          --data-urlencode "filter=hardware.serialNumber==\"${SERIAL_NUMBER}\"" \
          --data-urlencode "section=USER_AND_LOCATION" | \
        /usr/bin/plutil -extract results.0.userAndLocation.email raw -o - - 2>/dev/null
      )"
      LOOKUP_RC=$?
      set -e

      if [[ $LOOKUP_RC -eq 0 && -n "${MDM_API_EMAIL:-}" ]]; then
        BZ_EMAIL="$(printf '%s' "$MDM_API_EMAIL" | tr -d '[:space:]')"
        EMAIL_SOURCE="MDM inventory email"
        log "MDM API returned assigned user email: ${BZ_EMAIL}"
        if [[ "$BZ_EMAIL" != *"@"* ]]; then
          log "ERROR: MDM API returned an invalid email value: '${BZ_EMAIL}'"
          exit 1
        fi
      else
        log "WARN: MDM API lookup completed but did not return an email."
      fi
    else
      log "WARN: MDM API token request failed or returned no token."
    fi
  fi
fi

if [[ -n "${BZ_EMAIL:-}" ]]; then
  if [[ "$BZ_EMAIL" != *"@"* ]]; then
    log "ERROR: Resolved Backblaze email does not look valid: '${BZ_EMAIL}'"
    exit 1
  fi
  log "Resolved Backblaze email: ${BZ_EMAIL} (source: ${EMAIL_SOURCE:-unknown})"
else
  log "INFO: Backblaze install deferred because MDM inventory email is not available yet."
  log "  CURRENT_USER='${CURRENT_USER:-}'"
  log "  ADDIGY_USER_NAME='${ADDIGY_USER_NAME:-}'"
  log "  SERIAL_NUMBER='${SERIAL_NUMBER:-}'"
  if [[ -n "${MDM_API_URL:-}" ]]; then
    log "  MDM_API_CONFIGURED='yes'"
  else
    log "  MDM_API_CONFIGURED='no'"
  fi
fi

#############################################
# VALIDATION 
#############################################
if [[ -z "$BZ_GROUP_ID" || -z "$BZ_GROUP_TOKEN" ]]; then
  log "ERROR: Missing required values for Business Group enrollment."
  log "  BZ_GROUP_ID='${BZ_GROUP_ID}'"
  log "Provide via Addigy variables or parameters $4-$5."
  exit 1
fi

if [[ -z "$BZ_EMAIL" ]]; then
  log "INFO: No MDM inventory email is available yet, so Backblaze onboarding will be skipped for now."
  log "INFO: This is expected for newly enrolled devices before User and Location is populated."
  exit 0
fi

#############################################
# INTERNAL CONSTANTS
#############################################
BZ_DMG_PATH="/tmp/backblaze_installer.dmg"
BZ_PLIST="/tmp/backblaze_hdiutil.plist"
BZ_MOUNTPOINT=""
BZ_INSTALLER=""

#############################################
# CLEANUP
#############################################
cleanup() {
  log "Cleanup…"
  if [[ -n "${BZ_MOUNTPOINT}" && -d "${BZ_MOUNTPOINT}" ]]; then
    /usr/sbin/diskutil unmount force "${BZ_MOUNTPOINT}" >/dev/null 2>&1 || true
  fi
  rm -f "$BZ_DMG_PATH" "$BZ_PLIST" >/dev/null 2>&1 || true
  if [[ -f "$RMM_LOG_FILE" ]]; then
    chmod 644 "$RMM_LOG_FILE" 2>/dev/null || true
  fi
  MDM_API_TOKEN=""
  MDM_API_EMAIL=""
}
trap cleanup EXIT

#############################################
# PRE-INSTALL DECISION
#############################################
log "Proceeding with Backblaze onboarding because a valid email is available from: ${EMAIL_SOURCE:-unknown}"
log "RMM log file: ${RMM_LOG_FILE}"

#############################################
# DOWNLOAD DMG
#############################################
log "Downloading installer DMG:"
log "  URL: $BZ_DMG_URL"

curl -fLsS --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 900 \
  "$BZ_DMG_URL" -o "$BZ_DMG_PATH"

#############################################
# MOUNT DMG (robust mount point detection)
#############################################
log "Mounting DMG…"

set +e
ATTACH_PLIST_OUT="$(hdiutil attach -nobrowse -plist "$BZ_DMG_PATH" 2>&1)"
HDIUTIL_RC=$?
set -e

if [[ $HDIUTIL_RC -ne 0 ]]; then
  log "ERROR: hdiutil attach failed (rc=${HDIUTIL_RC})."
  log "ERROR: hdiutil output:"
  echo "$ATTACH_PLIST_OUT"
  log "ERROR: DMG details (ls -lh):"
  ls -lh "$BZ_DMG_PATH" || true
  exit 1
fi

printf '%s\n' "$ATTACH_PLIST_OUT" > "$BZ_PLIST"

MOUNT_POINTS="$(/usr/libexec/PlistBuddy -c "Print :system-entities" "$BZ_PLIST" 2>/dev/null | awk -F'= ' '/mount-point =/ {print $2}')"

if [[ -n "$MOUNT_POINTS" ]]; then
  while IFS= read -r mp; do
    if [[ -n "$mp" && -d "$mp" ]]; then
      BZ_MOUNTPOINT="$mp"
      break
    fi
  done <<< "$MOUNT_POINTS"
fi

if [[ -z "$BZ_MOUNTPOINT" ]]; then
  log "ERROR: mount point parse failed; got no valid /Volumes path from hdiutil plist output."
  log "DEBUG: Parsed mount-points (raw):"
  echo "$MOUNT_POINTS" || true
  log "DEBUG: First 60 lines of returned plist (if present):"
  sed -n '1,60p' "$BZ_PLIST" 2>/dev/null || true
  exit 1
fi

log "Mounted at: $BZ_MOUNTPOINT"

BZ_INSTALLER="$(/usr/bin/find "$BZ_MOUNTPOINT" -maxdepth 6 -type f -name "bzinstall_mate" -perm -111 2>/dev/null | /usr/bin/head -n 1)"

if [[ -z "${BZ_INSTALLER:-}" || ! -x "$BZ_INSTALLER" ]]; then
  log "ERROR: Installer binary 'bzinstall_mate' not found in mounted DMG at: $BZ_MOUNTPOINT"
  if /bin/ls -1 "$BZ_MOUNTPOINT" 2>/dev/null | grep -qi "BackblazeDownloader.app"; then
    log "HINT: This looks like a Downloader DMG (contains BackblazeDownloader.app). Use the Installer DMG instead."
  fi
  log "Listing mount root for troubleshooting:"
  ls -la "$BZ_MOUNTPOINT" || true
  exit 1
fi

log "Found installer: $BZ_INSTALLER"

#############################################
# INSTALL OR UPGRADE
#############################################
rc=0

run_bzinstall_with_logging() {
  local label="$1"
  shift

  log "Installer arg pattern (${label}): $*"
}

capture_bzinstall_run() {
  local label="$1"
  shift

  local install_out
  set +e
  install_out="$("$BZ_INSTALLER" "$@" 2>&1)"
  rc=$?
  set -e

  if [[ -n "$install_out" ]]; then
    echo "$install_out" | tee -a "$LOG_FILE" >/dev/null
  else
    log "WARN: bzinstall_mate produced no stdout/stderr output for ${label}."
  fi

  log "bzinstall_mate final exit code (${label}): $rc"
}

log_failed_install_diagnostics() {
  log "Collecting post-failure diagnostics..."
  log "RMM log file for support collection: ${RMM_LOG_FILE}"

  if [[ -d "/Library/Backblaze.bzpkg" ]]; then
    log "Contents of /Library/Backblaze.bzpkg:"
    ls -la "/Library/Backblaze.bzpkg" | tee -a "$LOG_FILE" >/dev/null || true
  else
    log "WARN: /Library/Backblaze.bzpkg does not exist after failed install."
  fi

  if [[ -f "/Library/Backblaze.bzpkg/bzinstall.xml" ]]; then
    log "Found bzinstall.xml (showing first 80 lines):"
    sed -n '1,80p' "/Library/Backblaze.bzpkg/bzinstall.xml" | tee -a "$LOG_FILE" >/dev/null || true
  fi

  if [[ -f "/Library/Backblaze.bzpkg/bzdata/bzlogs/bzinstall.log" ]]; then
    log "Tail of bzinstall.log:"
    tail -n 80 "/Library/Backblaze.bzpkg/bzdata/bzlogs/bzinstall.log" | tee -a "$LOG_FILE" >/dev/null || true
  fi

  if [[ -f "/Library/Backblaze.bzpkg/bzdata/bzlogs/bztransmit.log" ]]; then
    log "Tail of bztransmit.log:"
    tail -n 80 "/Library/Backblaze.bzpkg/bzdata/bzlogs/bztransmit.log" | tee -a "$LOG_FILE" >/dev/null || true
  fi
}

if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed — performing silent upgrade…"
  set +e
  UPGRADE_OUT="$($BZ_INSTALLER --silentUpgrade 2>&1)"
  rc=$?
  set -e

  if [[ -n "$UPGRADE_OUT" ]]; then
    echo "$UPGRADE_OUT" | tee -a "$LOG_FILE" >/dev/null
  else
    log "WARN: bzinstall_mate produced no stdout/stderr output for silent upgrade."
  fi

  if [[ $rc -ne 0 ]] && echo "$UPGRADE_OUT" | grep -qi "installed version" && echo "$UPGRADE_OUT" | grep -qi "newer than the installer version"; then
    log "WARN: Installed client appears newer than the installer DMG; treating as no-op success."
    rc=0
  fi
else
  log "Fresh Backblaze Business Group install for resolved user email ${BZ_EMAIL}…"
  log "Installer group id: ${BZ_GROUP_ID}"
  log "Installer region: ${BZ_REGION:-<not set>}"
  log "Installer email source: ${EMAIL_SOURCE:-unknown}"

  INSTALL_ARGS=(--createaccount_or_signinaccount
                -emailAddress "$BZ_EMAIL"
                -groupId "$BZ_GROUP_ID"
                -groupAuthToken "$BZ_GROUP_TOKEN")

  INSTALL_ARGS_LOG=(--createaccount_or_signinaccount
                    -emailAddress "$BZ_EMAIL"
                    -groupId "$BZ_GROUP_ID"
                    -groupAuthToken "[REDACTED]")

  if [[ -n "$BZ_REGION" ]]; then
    INSTALL_ARGS+=(-region "$BZ_REGION")
    INSTALL_ARGS_LOG+=(-region "$BZ_REGION")
  fi

  run_bzinstall_with_logging "named-args" "${INSTALL_ARGS_LOG[@]}"
  capture_bzinstall_run "named-args" "${INSTALL_ARGS[@]}"
fi

log "bzinstall_mate exit code: $rc"
if [[ "$rc" -ne 0 ]]; then
  log_failed_install_diagnostics
  log "ERROR: Backblaze installer failed. Exit code: $rc"
  exit "$rc"
fi

#############################################
# VERIFY SERVICE (retry loop)
#############################################
log "Waiting for Backblaze service 'bzserv' to start…"
for _ in {1..30}; do
  if pgrep -x "bzserv" >/dev/null 2>&1; then
    log "bzserv is running."
    break
  fi
  sleep 2
done

if ! pgrep -x "bzserv" >/dev/null 2>&1; then
  log "ERROR: Backblaze service 'bzserv' is not running after install."
  exit 1
fi


#############################################
#############################################
# START BZMENU (menu bar icon)
#############################################
BZMENU_APP="/Library/Backblaze.bzpkg/bzbmenu.app"
BZMENU_BIN="${BZMENU_APP}/Contents/MacOS/bzbmenu"
TARGET_USER="${CURRENT_USER:-${ADDIGY_USER_NAME:-}}"

if [[ -n "${TARGET_USER:-}" && "${TARGET_USER}" != "root" && "${TARGET_USER}" != "loginwindow" ]]; then
  if pgrep -x "bzbmenu" >/dev/null 2>&1; then
    log "bzbmenu is already running."
  elif [[ -x "$BZMENU_BIN" ]]; then
    log "Attempting to launch bzbmenu for user ${TARGET_USER}."
    launchctl asuser "$(id -u "$TARGET_USER")" "$BZMENU_BIN" >/dev/null 2>&1 || \
      su - "$TARGET_USER" -c "'$BZMENU_BIN' >/dev/null 2>&1 &" || \
      log "WARN: Failed to launch bzbmenu for user ${TARGET_USER}."
  else
    log "WARN: bzbmenu binary not found at $BZMENU_BIN"
  fi
else
  log "INFO: No suitable logged-in user is available to launch bzbmenu yet."
fi

#############################################
# OPTIONAL: START/RESUME BACKUP (best-effort)
#############################################
normalize_bool() {
  local v
  v="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

BZTRANSMIT="/Library/Backblaze.bzpkg/bztransmit"

if normalize_bool "${BZ_START_BACKUP:-}"; then
  log "Start-backup requested (BZ_START_BACKUP=${BZ_START_BACKUP})."

  if [[ -x "$BZTRANSMIT" ]]; then
    HELP_OUT="$($BZTRANSMIT -help 2>&1 || true)"

    run_if_supported() {
      local flag="$1"
      if echo "$HELP_OUT" | grep -q "${flag}"; then
        log "Attempting: bztransmit ${flag}"
        "${BZTRANSMIT}" "${flag}" >/dev/null 2>&1 || true
        return 0
      fi
      return 1
    }

    run_if_supported "-resume" || run_if_supported "-unpause" || true
    run_if_supported "-backupnow" || run_if_supported "-startbackup" || true

    log "Start-backup step completed (best-effort)."
  else
    log "WARN: bztransmit not found/executable at $BZTRANSMIT; skipping start-backup step."
  fi
else
  log "Start-backup not requested (set Addigy variable/parameter $11 or env BZ_START_BACKUP=1 to enable)."
fi

log "RMM log file available at: ${RMM_LOG_FILE}"
log "Backblaze client installed and running. Group ID: $BZ_GROUP_ID"
log "=== Backblaze Business Group install completed successfully ==="
exit 0
