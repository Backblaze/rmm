#!/bin/bash
# Backblaze Desktop Client (macOS) - Generic Installer
#
# Supports installing from a DMG URL and (optionally) Business Group enrollment.
#
# Required for enrollment install:
#   BZ_EMAIL, BZ_GROUP_ID, BZ_GROUP_TOKEN
#
# Optional:
#   BZ_REGION
#   BZ_DMG_URL (defaults to a v10 installer URL placeholder)
#
# Example:
#   sudo BZ_EMAIL="user@company.com" BZ_GROUP_ID="123" BZ_GROUP_TOKEN="abc" \
#     BZ_DMG_URL="https://f000.backblazeb2.com/file/b2-computer-backup-files/macos/downloader/bzdownloader-mac-10.0.0.1028.dmg" \
#     bash install-backblaze.sh

set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/backblaze_install.log}"
DMG_PATH="${DMG_PATH:-/tmp/backblaze_installer.dmg}"
MOUNT_POINT=""

log() {
  local msg
  msg="[$(/bin/date '+%Y-%m-%d %H:%M:%S')] [backblaze][install] $*"
  if ! { touch "$LOG_FILE" 2>/dev/null; }; then
    LOG_FILE="/tmp/backblaze_install.log"
  fi
  echo "$msg" | tee -a "$LOG_FILE"
}


cleanup() {
  if [[ -n "${MOUNT_POINT:-}" ]]; then
    # diskutil is generally more reliable for DMG volume unmounts
    diskutil unmount "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  if [[ "${KEEP_DMG:-0}" != "1" ]]; then
    rm -f "$DMG_PATH" >/dev/null 2>&1 || true
  else
    log "KEEP_DMG=1 set; leaving DMG at $DMG_PATH"
  fi
}
trap cleanup EXIT

BZ_DMG_URL="${BZ_DMG_URL:-""}"

# If you want a default for UAT, set it here; otherwise require the caller to provide.
if [[ -z "$BZ_DMG_URL" ]]; then
  log "ERROR: BZ_DMG_URL is required (DMG download URL)."
  exit 2
fi

log "=== START ==="

if [[ ${EUID} -ne 0 ]]; then
  log "ERROR: must run as root (use sudo)."
  exit 1
fi

log "Downloading DMG: $BZ_DMG_URL"
curl -fsSL "$BZ_DMG_URL" -o "$DMG_PATH"

log "Mounting DMG..."

# Attach the DMG and capture output so mount errors are visible in logs.
set +e
HDI_OUT="$(hdiutil attach -nobrowse "$DMG_PATH" 2>&1)"
HDI_RC=$?
set -e

# Always log hdiutil output for troubleshooting.
echo "$HDI_OUT" | tee -a "$LOG_FILE" >/dev/null

if [[ $HDI_RC -ne 0 ]]; then
  log "ERROR: hdiutil attach failed (rc=$HDI_RC)."
  exit 3
fi

# Parse the mount point from the last column of the last output line.
# Example output line (last column is mount point):
# /dev/disk4s1  Apple_HFS  Backblaze Installer  /Volumes/Backblaze Installer
MOUNT_POINT="$(echo "$HDI_OUT" | /usr/bin/sed -n 's|.*\(/Volumes/.*\)$|\1|p' | /usr/bin/tail -n 1)"

if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  log "ERROR: failed to mount DMG."
  log "ERROR: mount point parse failed; got MOUNT_POINT='$MOUNT_POINT'"
  exit 3
fi
log "Mounted at: $MOUNT_POINT"

# Some DMGs may mount with a slightly different volume name; ensure we can locate the app.
if [[ ! -d "$MOUNT_POINT/Backblaze Installer.app" ]]; then
  # Try to find the installer app within the mount.
  FOUND_APP="$(/usr/bin/find "$MOUNT_POINT" -maxdepth 2 -name 'Backblaze Installer.app' -type d 2>/dev/null | head -n 1 || true)"
  if [[ -n "$FOUND_APP" ]]; then
    MOUNT_POINT="$(/usr/bin/dirname "$FOUND_APP")"
    log "Adjusted mount point to: $MOUNT_POINT"
  fi
fi

INSTALLER="$MOUNT_POINT/Backblaze Installer.app/Contents/MacOS/bzinstall_mate"
if [[ ! -x "$INSTALLER" ]]; then
  log "ERROR: installer not found at: $INSTALLER"
  exit 4
fi

# If Backblaze already installed, do a silent upgrade
if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed; running silent upgrade..."

  # Capture output so we can detect benign version-mismatch cases.
  set +e
  UPGRADE_OUT="$($INSTALLER --silentUpgrade 2>&1)"
  RC=$?
  set -e

  if [[ -n "$UPGRADE_OUT" ]]; then
    echo "$UPGRADE_OUT" | tee -a "$LOG_FILE" >/dev/null
  fi

  # UAT safeguard: treat "installed version is newer than the installer version" as a no-op success.
  # This can happen when testing a newer client against an older/incorrectly-versioned DMG.
  if [[ $RC -ne 0 ]] && echo "$UPGRADE_OUT" | grep -qi "installed version" && echo "$UPGRADE_OUT" | grep -qi "newer than the installer version"; then
    log "WARN: Installed client appears newer than installer DMG; treating as no-op success."
    RC=0
  fi

  log "Upgrade exit code: $RC"
  exit "$RC"
fi

# Optional group enrollment install
if [[ -n "${BZ_EMAIL:-}" && -n "${BZ_GROUP_ID:-}" && -n "${BZ_GROUP_TOKEN:-}" ]]; then
  log "Fresh install with Business Group enrollment for: ${BZ_EMAIL}"

  ARGS=(--createaccount_or_signinaccount
        -emailAddress "$BZ_EMAIL"
        -groupId "$BZ_GROUP_ID"
        -groupAuthToken "$BZ_GROUP_TOKEN")

  if [[ -n "${BZ_REGION:-}" ]]; then
    ARGS+=(-region "$BZ_REGION")
  fi

  set +e
  "$INSTALLER" "${ARGS[@]}" >>"$LOG_FILE" 2>&1
  RC=$?
  set -e
  log "Install exit code: $RC"
  exit "$RC"
fi

# Fallback: installer UI-less install (no enrollment)
log "Fresh install (no group enrollment vars provided). Running installer with no enrollment arguments..."
set +e
"$INSTALLER" >>"$LOG_FILE" 2>&1
RC=$?
set -e
log "Install exit code: $RC"
exit "$RC"