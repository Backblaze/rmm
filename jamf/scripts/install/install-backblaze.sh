#!/bin/bash
# Backblaze Business Install (Optimized for Jamf Pro) - v10 internal build
#
# Jamf Pro Script Parameters:
#   $4 = Backblaze Group ID
#   $5 = Backblaze Group Token
#   $6 = Backblaze Email
#   $7 = Backblaze Region (optional)
#
# Local testing (optional): supports getopts
#   -g <group_id> -t <group_token> -e <email> [-r <region>] [-u <dmg_url>]
#
# Notes:
# - Requires root (Jamf runs scripts as root).
# - Uses internal v10 DMG URL by default.
# - Verifies success by checking bzserv is running (with a retry loop).
# - Logs to /var/log/backblaze_mdm_install.log

set -euo pipefail

#############################################
# DEFAULTS (can be overridden)
#############################################
BZ_GROUP_ID="${BZ_GROUP_ID:-""}"
BZ_GROUP_TOKEN="${BZ_GROUP_TOKEN:-""}"
BZ_EMAIL="${BZ_EMAIL:-""}"
BZ_REGION="${BZ_REGION:-""}"

BZ_DMG_URL_DEFAULT="https://f000.backblazeb2.com/file/b2-computer-backup-files/macos/downloader/bzdownloader-mac-10.0.0.1012.dmg"
BZ_DMG_URL="${BZ_DMG_URL:-$BZ_DMG_URL_DEFAULT}"

#############################################
# JAMF PARAMETERS (preferred in Jamf)
#############################################
# $1 mountPoint, $2 computerName, $3 userName, $4+ custom
if [[ "${4-}" != "" ]]; then BZ_GROUP_ID="$4"; fi
if [[ "${5-}" != "" ]]; then BZ_GROUP_TOKEN="$5"; fi
if [[ "${6-}" != "" ]]; then BZ_EMAIL="$6"; fi
if [[ "${7-}" != "" ]]; then BZ_REGION="$7"; fi

#############################################
# LOCAL CLI OVERRIDES (optional)
#############################################
# If you run this locally and want flags, they override Jamf params/env.
while getopts ":g:t:e:r:u:" opt; do
  case "$opt" in
    g) BZ_GROUP_ID="$OPTARG" ;;
    t) BZ_GROUP_TOKEN="$OPTARG" ;;
    e) BZ_EMAIL="$OPTARG" ;;
    r) BZ_REGION="$OPTARG" ;;
    u) BZ_DMG_URL="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; exit 2 ;;
  esac
done

#############################################
# INTERNAL CONSTANTS
#############################################
BZ_DMG_PATH="/tmp/install_backblaze.dmg"
BZ_MOUNT=""   # will be detected dynamically
BZ_INSTALLER=""  # will be set after mount
LOG_FILE="/var/log/backblaze_mdm_install.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# Log to file + stdout
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== Backblaze Business install started ==="

#############################################
# SAFETY & VALIDATION
#############################################
if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: Script must run as root."
  exit 1
fi

if [[ -z "$BZ_GROUP_ID" || -z "$BZ_GROUP_TOKEN" || -z "$BZ_EMAIL" ]]; then
  log "ERROR: Missing required values."
  log "  BZ_GROUP_ID='$BZ_GROUP_ID'"
  log "  BZ_GROUP_TOKEN length=${#BZ_GROUP_TOKEN}"
  log "  BZ_EMAIL='$BZ_EMAIL'"
  log "Provide via Jamf params ($4-$6), env vars, or local flags (-g -t -e)."
  exit 1
fi

#############################################
# CLEANUP HANDLER
#############################################
cleanup() {
  log "Running cleanup…"
  if [[ -n "${BZ_MOUNT:-}" && -d "${BZ_MOUNT:-}" ]]; then
    hdiutil detach "$BZ_MOUNT" >/dev/null 2>&1 || true
  fi
  rm -f "$BZ_DMG_PATH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

#############################################
# DOWNLOAD INSTALLER
#############################################
log "Downloading Backblaze installer DMG from: $BZ_DMG_URL"
curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 900 \
  "$BZ_DMG_URL" -o "$BZ_DMG_PATH"

#############################################
# MOUNT DMG (dynamic mount detection)
#############################################
log "Mounting installer DMG…"
ATTACH_OUT="$(hdiutil attach -nobrowse -readonly "$BZ_DMG_PATH")"
BZ_MOUNT="$(echo "$ATTACH_OUT" | awk -F'\t' '/\/Volumes\// {print $NF; exit}')"

if [[ -z "$BZ_MOUNT" || ! -d "$BZ_MOUNT" ]]; then
  log "ERROR: Could not determine DMG mount point."
  log "hdiutil output:"
  echo "$ATTACH_OUT"
  exit 1
fi

BZ_INSTALLER="$BZ_MOUNT/Backblaze Installer.app/Contents/MacOS/bzinstall_mate"
log "Mounted DMG at: $BZ_MOUNT"

if [[ ! -x "$BZ_INSTALLER" ]]; then
  log "ERROR: Backblaze installer not found or not executable at: $BZ_INSTALLER"
  log "Listing mount root for troubleshooting:"
  ls -la "$BZ_MOUNT" || true
  exit 1
fi

#############################################
# INSTALL OR UPGRADE
#############################################
rc=0
if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed – performing silent upgrade…"
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
for i in {1..30}; do
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
# OPTIONAL: LOG INSTALLED VERSION VIA bzcli
#############################################
if [[ -x "/usr/local/bin/bzcli" ]]; then
  INSTALLED_VER="$(/usr/local/bin/bzcli report -v /backup/installation/version 2>/dev/null || true)"
  INSTALLED_VER="${INSTALLED_VER#"${INSTALLED_VER%%[![:space:]]*}"}"
  INSTALLED_VER="${INSTALLED_VER%"${INSTALLED_VER##*[![:space:]]}"}"
  log "Installed Backblaze version (bzcli): ${INSTALLED_VER:-unknown}"
else
  log "Note: bzcli not found at /usr/local/bin/bzcli (may not be installed yet or path differs)."
fi

log "Backblaze client installed and running. Group ID: $BZ_GROUP_ID"
log "=== Backblaze Business install completed successfully ==="
exit 0