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
#     BZ_DMG_URL="https://f000.backblazeb2.com/file/.../bzinstall-mac-10.0.0.1016.dmg" \
#     bash install-backblaze.sh

set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/backblaze_install.log}"
DMG_PATH="${DMG_PATH:-/tmp/backblaze_installer.dmg}"
MOUNT_POINT=""

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][install] $*"
  if ! { touch "$LOG_FILE" 2>/dev/null; }; then
    LOG_FILE="/tmp/backblaze_install.log"
  fi
  echo "$msg" | tee -a "$LOG_FILE"
}

cleanup() {
  if [[ -n "${MOUNT_POINT:-}" ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet >/dev/null 2>&1 || true
  fi
  rm -f "$DMG_PATH" >/dev/null 2>&1 || true
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
# Capture mount point reliably
MOUNT_POINT="$(hdiutil attach -nobrowse -quiet "$DMG_PATH" | awk 'END{print $3}')"
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  log "ERROR: failed to mount DMG."
  exit 3
fi
log "Mounted at: $MOUNT_POINT"

INSTALLER="$MOUNT_POINT/Backblaze Installer.app/Contents/MacOS/bzinstall_mate"
if [[ ! -x "$INSTALLER" ]]; then
  log "ERROR: installer not found at: $INSTALLER"
  exit 4
fi

# If Backblaze already installed, do a silent upgrade
if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed; running silent upgrade..."
  set +e
  "$INSTALLER" --silentUpgrade >>"$LOG_FILE" 2>&1
  RC=$?
  set -e
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