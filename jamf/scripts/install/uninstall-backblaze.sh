#!/bin/bash
# Backblaze Uninstall (Jamf Pro)
# Safe, idempotent uninstall with logging and vendor uninstaller support

set -euo pipefail

LOG_FILE="/var/log/backblaze_mdm_uninstall.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][uninstall] $*"; }
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== START Backblaze uninstall ==="

if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: must run as root"
  exit 1
fi

BZPKG="/Library/Backblaze.bzpkg"
UNINSTALL_BIN="${BZPKG}/UninstallBackblaze.app/Contents/MacOS/UninstallBackblaze"
UNINSTALL_RESOURCES_DIR="${BZPKG}/UninstallBackblaze.app/Contents/Resources"

log "Stopping Backblaze processes (best-effort)"
pkill -x bzbmenu 2>/dev/null || true
pkill -x bztransmit 2>/dev/null || true
pkill -x bzserv 2>/dev/null || true
sleep 2

log "Unloading launchd items (best-effort)"
launchctl bootout system /Library/LaunchDaemons/com.backblaze.* 2>/dev/null || true
launchctl bootout gui/0 /Library/LaunchAgents/com.backblaze.* 2>/dev/null || true

if [[ -x "$UNINSTALL_BIN" ]]; then
  log "Running vendor uninstaller: $UNINSTALL_BIN"
  if [[ -d "$UNINSTALL_RESOURCES_DIR" ]]; then
    log "Vendor uninstaller resources directory: $UNINSTALL_RESOURCES_DIR"
  fi
  set +e
  "$UNINSTALL_BIN" >/dev/null 2>&1
  rc=$?
  set -e
  log "Vendor uninstaller exit code: $rc"
else
  log "Vendor uninstaller not found at: $UNINSTALL_BIN; continuing manual cleanup"
fi

log "Removing Backblaze directories (best-effort cleanup after vendor uninstall)"
rm -rf "/Library/Application Support/Backblaze" 2>/dev/null || true
rm -rf "/Library/Backblaze.bzpkg" 2>/dev/null || true

log "Removing Applications stubs"
rm -rf "/Applications/Backblaze.app" 2>/dev/null || true
rm -rf "/Applications/Backblaze Restore.app" 2>/dev/null || true

log "Removing preference files"
rm -f /Library/Preferences/com.backblaze.* 2>/dev/null || true
rm -f /Library/LaunchDaemons/com.backblaze.* 2>/dev/null || true
rm -f /Library/LaunchAgents/com.backblaze.* 2>/dev/null || true

log "Removing per-user Backblaze data"
for udir in /Users/*; do
  [[ -d "$udir" ]] || continue
  rm -f "$udir/Library/Preferences/com.backblaze."* 2>/dev/null || true
  rm -rf "$udir/Library/Application Support/Backblaze" 2>/dev/null || true
done

if pgrep -x bzserv >/dev/null 2>&1; then
  log "WARN: bzserv still running"
else
  log "OK: bzserv not running"
fi

log "=== DONE Backblaze uninstall ==="
exit 0
