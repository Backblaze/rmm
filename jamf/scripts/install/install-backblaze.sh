#!/bin/bash
# Backblaze Business Group Install (Jamf Pro) — UAT
#
# Purpose:
#   UAT-focused installer that enrolls/signs-in devices to a Backblaze Business Group.
#   This script REQUIRES Group enrollment parameters.
#
# Jamf Script Parameters:
#   $4 = Backblaze Group ID            (required)
#   $5 = Backblaze Group Auth Token    (required)
#   $6 = Backblaze Email               (required)
#   $7 = Backblaze Region              (optional)
#   $8 = DMG URL override              (optional)
#   $9 = Start backup after install  (optional; 1/true/yes to enable)
#
# Defaults:
#   - Uses internal v10 DMG by default (UAT)
#   - Installs or silently upgrades if already installed
#   - Verifies bzserv is running (retry loop)
#
# Notes:
# - Jamf runs scripts as root.
# - Logs to stdout + /var/log/backblaze_mdm_install.log
# - Does NOT print tokens.

set -euo pipefail

#############################################
# LOGGING
#############################################
LOG_FILE="/var/log/backblaze_mdm_install.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== Backblaze Business Group install started (UAT) ==="

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

# UAT default: internal v10 build DMG (can be overridden by $8)
BZ_DMG_URL_DEFAULT="https://f000.backblazeb2.com/file/b2-computer-backup-files/macos/computerbackup/bzinstall-mac-10.0.0.1016.dmg"
BZ_DMG_URL="${BZ_DMG_URL:-$BZ_DMG_URL_DEFAULT}"

#############################################
# JAMF PARAMETERS OVERRIDE
#############################################
# Jamf passes: $1 mountPoint, $2 computerName, $3 userName, $4+ custom
if [[ -n "${4-}" ]]; then BZ_GROUP_ID="$4"; fi
if [[ -n "${5-}" ]]; then BZ_GROUP_TOKEN="$5"; fi
if [[ -n "${6-}" ]]; then BZ_EMAIL="$6"; fi
if [[ -n "${7-}" ]]; then BZ_REGION="$7"; fi
if [[ -n "${8-}" ]]; then BZ_DMG_URL="$8"; fi
if [[ -n "${9-}" ]]; then BZ_START_BACKUP="$9"; fi

#############################################
# VALIDATION (UAT requires enrollment params)
#############################################
if [[ -z "$BZ_GROUP_ID" || -z "$BZ_GROUP_TOKEN" || -z "$BZ_EMAIL" ]]; then
  log "ERROR: Missing required values for Business Group enrollment."
  log "  BZ_GROUP_ID='${BZ_GROUP_ID}'"
  log "  BZ_EMAIL='${BZ_EMAIL}'"
  log "Provide via Jamf parameters $4-$6 (recommended) or env vars."
  exit 1
fi

#############################################
# INTERNAL CONSTANTS
#############################################
BZ_DMG_PATH="/tmp/backblaze_installer.dmg"
BZ_PLIST="/tmp/backblaze_hdiutil.plist"
BZ_MOUNTPOINT=""
BZ_INSTALLER_REL="Backblaze Installer.app/Contents/MacOS/bzinstall_mate"

#############################################
# CLEANUP
#############################################
cleanup() {
  log "Cleanup…"
  if [[ -n "${BZ_MOUNTPOINT}" && -d "${BZ_MOUNTPOINT}" ]]; then
    /usr/sbin/diskutil unmount force "${BZ_MOUNTPOINT}" >/dev/null 2>&1 || true
  fi
  rm -f "$BZ_DMG_PATH" "$BZ_PLIST" >/dev/null 2>&1 || true
}
trap cleanup EXIT

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

# NOTE: With `set -e`, a failing `hdiutil attach` can exit before Jamf captures useful output.
# Capture stdout/stderr and log it on failure.
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

# Persist the returned plist to disk for parsing below.
printf '%s\n' "$ATTACH_PLIST_OUT" > "$BZ_PLIST"

# Extract mount-point(s) from plist. PlistBuddy prints lines like:
#   mount-point = /Volumes/Backblaze Installer
# Grab all mount points, then pick the first existing directory.
MOUNT_POINTS="$(/usr/libexec/PlistBuddy -c "Print :system-entities" "$BZ_PLIST" 2>/dev/null | awk -F'= ' '/mount-point =/ {print $2}')"

if [[ -n "$MOUNT_POINTS" ]]; then
  while IFS= read -r mp; do
    if [[ -n "$mp" && -d "$mp" ]]; then
      BZ_MOUNTPOINT="$mp"
      break
    fi
  done <<< "$MOUNT_POINTS"
fi

 # Fallback: if we still can't find a mount point, dump what we parsed for troubleshooting.
# Do NOT call hdiutil attach again (that can create duplicate mounts like "Backblaze Installer 3").
if [[ -z "$BZ_MOUNTPOINT" ]]; then
  log "ERROR: mount point parse failed; got no valid /Volumes path from hdiutil plist output."
  log "DEBUG: Parsed mount-points (raw):"
  echo "$MOUNT_POINTS" || true
  log "DEBUG: First 60 lines of returned plist (if present):"
  sed -n '1,60p' "$BZ_PLIST" 2>/dev/null || true
  exit 1
fi

log "Mounted at: $BZ_MOUNTPOINT"

BZ_INSTALLER="${BZ_MOUNTPOINT}/${BZ_INSTALLER_REL}"
if [[ ! -x "$BZ_INSTALLER" ]]; then
  log "ERROR: Installer not found/executable at: $BZ_INSTALLER"
  log "Listing mount root for troubleshooting:"
  ls -la "$BZ_MOUNTPOINT" || true
  exit 1
fi

#############################################
# INSTALL OR UPGRADE
#############################################
rc=0

if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed — performing silent upgrade…"
  set +e
  UPGRADE_OUT="$("$BZ_INSTALLER" --silentUpgrade 2>&1)"
  rc=$?
  set -e

  # Always log installer output for troubleshooting (may include benign version comparisons).
  if [[ -n "$UPGRADE_OUT" ]]; then
    echo "$UPGRADE_OUT" | tee -a "$LOG_FILE" >/dev/null
  fi

  # UAT safeguard: treat "installed version is newer than the installer" as a no-op success.
  # This can happen when testing a newer client against an older/incorrectly-versioned DMG.
  if [[ $rc -ne 0 ]] && echo "$UPGRADE_OUT" | grep -qi "installed version" && echo "$UPGRADE_OUT" | grep -qi "newer than the installer version"; then
    log "WARN: Installed client appears newer than the installer DMG; treating as no-op success."
    rc=0
  fi
else
  log "Fresh Backblaze Business Group install for $BZ_EMAIL…"

  INSTALL_ARGS=(--createaccount_or_signinaccount
                -emailAddress "$BZ_EMAIL"
                -groupId "$BZ_GROUP_ID"
                -groupAuthToken "$BZ_GROUP_TOKEN")

  if [[ -n "$BZ_REGION" ]]; then
    INSTALL_ARGS+=(-region "$BZ_REGION")
  fi

  set +e
  "$BZ_INSTALLER" "${INSTALL_ARGS[@]}"
  rc=$?
  set -e
fi

log "bzinstall_mate exit code: $rc"
if [[ "$rc" -ne 0 ]]; then
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
# OPTIONAL: START/RESUME BACKUP (best-effort)
#############################################
# We cannot programmatically grant macOS privacy permissions (FDA, Location, etc.) here.
# Jamf configuration profiles (PPPC + ServiceManagement) should be scoped separately.
# This section is best-effort and will not fail the install if the CLI command is unsupported.

normalize_bool() {
  # macOS ships Bash 3.2 by default; it does NOT support ${var,,} lowercase expansion.
  # Use `tr` to normalize to lowercase instead.
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
    # Determine which flags are supported by this client.
    HELP_OUT="$("$BZTRANSMIT" -help 2>&1 || true)"

    run_if_supported() {
      local flag="$1"
      if echo "$HELP_OUT" | grep -q "${flag}"; then
        log "Attempting: bztransmit ${flag}"
        "${BZTRANSMIT}" "${flag}" >/dev/null 2>&1 || true
        return 0
      fi
      return 1
    }

    # Most common: resume/unpause.
    run_if_supported "-resume" || run_if_supported "-unpause" || true

    # If the client supports an explicit backup trigger, try it.
    run_if_supported "-backupnow" || run_if_supported "-startbackup" || true

    log "Start-backup step completed (best-effort)."
  else
    log "WARN: bztransmit not found/executable at $BZTRANSMIT; skipping start-backup step."
  fi
else
  log "Start-backup not requested (set Jamf $9 or env BZ_START_BACKUP=1 to enable)."
fi

log "Backblaze client installed and running. Group ID: $BZ_GROUP_ID"
log "=== Backblaze Business Group install completed successfully (UAT) ==="
exit 0
