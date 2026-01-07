#!/bin/bash
# Backblaze Computer Backup (Mac) - Jamf Pro Installer
#
# Default behavior:
#   - Downloads Backblaze installer DMG
#   - Installs or silently upgrades if already installed
#   - Verifies bzserv is running
#
# Optional enrollment behavior (Business Group):
#   If Jamf Script Parameters $4-$6 are provided, the script will attempt
#   to enroll/sign-in the client into a Business Group after install.
#
# Jamf Script Parameters:
#   $4 = Backblaze Group ID            (optional)
#   $5 = Backblaze Group Auth Token    (optional)
#   $6 = Backblaze Email               (optional)
#   $7 = Backblaze Region              (optional)
#   $8 = DMG URL override              (optional)  <-- use for internal v10 builds/UAT
#
# Env var overrides (optional):
#   BZ_GROUP_ID, BZ_GROUP_TOKEN, BZ_EMAIL, BZ_REGION, BZ_DMG_URL
#
# Notes:
# - Jamf runs scripts as root.
# - Script logs to stdout + /var/log/backblaze_jamf_install.log
# - Does NOT print tokens in logs.

set -euo pipefail

#############################################
# LOGGING
#############################################
LOG_FILE="/var/log/backblaze_jamf_install.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== Backblaze install started ==="

#############################################
# REQUIRE ROOT
#############################################
if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: Must run as root."
  exit 1
fi

#############################################
# INPUTS (env defaults)
#############################################
BZ_GROUP_ID="${BZ_GROUP_ID:-""}"
BZ_GROUP_TOKEN="${BZ_GROUP_TOKEN:-""}"
BZ_EMAIL="${BZ_EMAIL:-""}"
BZ_REGION="${BZ_REGION:-""}"

# Customer-stable default (recommended default for repo)
BZ_DMG_URL_DEFAULT="https://secure.backblaze.com/groups/install_backblaze.dmg"
BZ_DMG_URL="${BZ_DMG_URL:-$BZ_DMG_URL_DEFAULT}"

#############################################
# JAMF PARAMETERS OVERRIDE (if present)
#############################################
# Jamf passes: $1 mountPoint, $2 computerName, $3 userName, $4+ custom
if [[ -n "${4-}" ]]; then BZ_GROUP_ID="$4"; fi
if [[ -n "${5-}" ]]; then BZ_GROUP_TOKEN="$5"; fi
if [[ -n "${6-}" ]]; then BZ_EMAIL="$6"; fi
if [[ -n "${7-}" ]]; then BZ_REGION="$7"; fi
if [[ -n "${8-}" ]]; then BZ_DMG_URL="$8"; fi

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
curl -fLsS "$BZ_DMG_URL" -o "$BZ_DMG_PATH"

#############################################
# MOUNT DMG (robust mount point detection)
#############################################
log "Mounting DMG…"
hdiutil attach -nobrowse -plist "$BZ_DMG_PATH" > "$BZ_PLIST"

# Extract mount-point from plist: system-entities array may contain multiple entries
# We'll take the first entry that has a "mount-point".
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
  exit 1
fi

#############################################
# INSTALL OR UPGRADE
#############################################
rc=0

if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze detected (bzserv running) — attempting silent upgrade…"
  set +e
  "$BZ_INSTALLER" --silentUpgrade
  rc=$?
  set -e
else
  log "Backblaze not detected — performing install…"
  set +e
  "$BZ_INSTALLER"
  rc=$?
  set -e
fi

log "Installer exit code: $rc"
if [[ "$rc" -ne 0 ]]; then
  log "ERROR: Installer failed."
  exit "$rc"
fi

#############################################
# OPTIONAL: BUSINESS GROUP ENROLLMENT
#############################################
# Only attempt enrollment if the admin provided the required values.
if [[ -n "$BZ_GROUP_ID" && -n "$BZ_GROUP_TOKEN" && -n "$BZ_EMAIL" ]]; then
  log "Enrollment parameters detected — attempting Business Group enrollment…"

  ENROLL_ARGS=(--createaccount_or_signinaccount
               -emailAddress "$BZ_EMAIL"
               -groupId "$BZ_GROUP_ID"
               -groupAuthToken "$BZ_GROUP_TOKEN")

  if [[ -n "$BZ_REGION" ]]; then
    ENROLL_ARGS+=(-region "$BZ_REGION")
  fi

  set +e
  "$BZ_INSTALLER" "${ENROLL_ARGS[@]}"
  enroll_rc=$?
  set -e

  log "Enrollment exit code: $enroll_rc"
  if [[ "$enroll_rc" -ne 0 ]]; then
    log "ERROR: Enrollment failed (install succeeded)."
    exit "$enroll_rc"
  fi
else
  log "No enrollment parameters provided — skipping Business Group enrollment."
fi

#############################################
# VERIFY SERVICE
#############################################
log "Verifying bzserv is running…"
sleep 8

if ! pgrep -x "bzserv" >/dev/null 2>&1; then
  log "ERROR: bzserv is not running after install."
  exit 1
fi

log "SUCCESS: Backblaze installed and bzserv is running."
log "=== Backblaze install completed ==="
exit 0
