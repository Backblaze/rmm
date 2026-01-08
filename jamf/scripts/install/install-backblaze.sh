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

# UAT default: internal v10 build DMG (can be overridden by $8)
BZ_DMG_URL_DEFAULT="https://f000.backblazeb2.com/file/b2-computer-backup-files/macos/downloader/bzdownloader-mac-10.0.0.1012.dmg"
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
    /usr/sbin/diskutil unmount "${BZ_MOUNTPOINT}" >/dev/null 2>&1 || true
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
hdiutil attach -nobrowse -plist "$BZ_DMG_PATH" > "$BZ_PLIST"

# Extract mount-point from plist. Take first entry that has a mount-point.
for i in $(/usr/libexec/PlistBuddy -c "Print :system-entities" "$BZ_PLIST" 2>/dev/null | awk '/Dict/ {print NR-1}' || true); do
  mp=$(/usr/libexec/PlistBuddy -c "Print :system-entities:${i}:mount-point" "$BZ_PLIST" 2>/dev/null || true)
  if [[ -n "$mp" && -d "$mp" ]]; then
    BZ_MOUNTPOINT="$mp"
    break
  fi
done

if [[ -z "$BZ_MOUNTPOINT" ]]; then
  log "ERROR: Could not determine DMG mount point."
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
  "$BZ_INSTALLER" --silentUpgrade
  rc=$?
  set -e
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

log "Backblaze client installed and running. Group ID: $BZ_GROUP_ID"
log "=== Backblaze Business Group install completed successfully (UAT) ==="
exit 0
