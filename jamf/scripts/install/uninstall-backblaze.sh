#!/bin/bash
# Backblaze Uninstall (Jamf Pro)
# Calls the official Backblaze uninstall script from the installed client package.
# Safe and idempotent for MDM usage.

set -euo pipefail

LOG_FILE="/var/log/backblaze_mdm_uninstall.log"
BZPKG="/Library/Backblaze.bzpkg"
OFFICIAL_UNINSTALLER="${BZPKG}/UninstallBackblaze.app/Contents/Resources/bzuninstaller.sh"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][uninstall] $*"; }
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== START Backblaze uninstall ==="

if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: must run as root"
  exit 1
fi

if [[ ! -d "$BZPKG" ]]; then
  log "Backblaze is not installed; nothing to uninstall"
  log "=== DONE Backblaze uninstall ==="
  exit 0
fi

if [[ ! -x "$OFFICIAL_UNINSTALLER" ]]; then
  log "ERROR: official Backblaze uninstaller not found or not executable: $OFFICIAL_UNINSTALLER"
  exit 1
fi

log "Running official Backblaze uninstaller: $OFFICIAL_UNINSTALLER"
set +e
"$OFFICIAL_UNINSTALLER"
rc=$?
set -e
log "Official Backblaze uninstaller exit code: $rc"

log "Verifying uninstall result"

if pgrep -x bzserv >/dev/null 2>&1; then
  log "WARN: bzserv is still running after uninstall"
else
  log "OK: bzserv is not running"
fi

if [[ -d "$BZPKG" ]]; then
  log "WARN: $BZPKG still exists after uninstall"
else
  log "OK: $BZPKG removed"
fi

if [[ -d "/Applications/Backblaze.app" ]]; then
  log "WARN: /Applications/Backblaze.app still exists after uninstall"
else
  log "OK: /Applications/Backblaze.app removed"
fi

log "=== DONE Backblaze uninstall ==="
exit "$rc"