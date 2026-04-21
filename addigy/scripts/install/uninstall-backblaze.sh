#!/bin/bash
# Backblaze Uninstall (Addigy)
# Wrapper around the vendor-supported Backblaze uninstaller with fallback cleanup

set -euo pipefail

LOG_FILE="/var/log/backblaze_mdm_uninstall.log"
RMM_LOG_DIR="/Library/Logs/BackblazeSilentInstaller"
RMM_LOG_FILE="${RMM_LOG_DIR}/rmm.log"
mkdir -p "$RMM_LOG_DIR"

touch "$LOG_FILE" "$RMM_LOG_FILE"
chmod 644 "$LOG_FILE" "$RMM_LOG_FILE" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE" "$RMM_LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][uninstall] $*"; }

log "=== START Backblaze uninstall ==="

if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: must run as root"
  exit 1
fi

BZPKG="/Library/Backblaze.bzpkg"
VENDOR_UNINSTALL_SCRIPT="${BZPKG}/UninstallBackblaze.app/Contents/Resources/bzuninstaller.sh"
VENDOR_UNINSTALL_BIN="${BZPKG}/UninstallBackblaze.app/Contents/MacOS/UninstallBackblaze"

if [[ ! -d "$BZPKG" ]]; then
  log "Backblaze not installed, nothing to do"
  log "RMM log file available at: ${RMM_LOG_FILE}"
  log "=== DONE Backblaze uninstall ==="
  exit 0
fi

run_vendor_uninstall() {
  local rc=1

  if [[ -x "$VENDOR_UNINSTALL_SCRIPT" ]]; then
    log "Running vendor uninstall script: $VENDOR_UNINSTALL_SCRIPT"
    set +e
    /bin/bash "$VENDOR_UNINSTALL_SCRIPT"
    rc=$?
    set -e
    log "Vendor uninstall script exit code: $rc"
    return "$rc"
  fi

  if [[ -x "$VENDOR_UNINSTALL_BIN" ]]; then
    log "Vendor uninstall script not found; running vendor binary: $VENDOR_UNINSTALL_BIN"
    set +e
    "$VENDOR_UNINSTALL_BIN" >/dev/null 2>&1
    rc=$?
    set -e
    log "Vendor uninstall binary exit code: $rc"
    return "$rc"
  fi

  log "Vendor uninstall resources not found; fallback cleanup will be used"
  return 1
}

fallback_cleanup() {
  log "Starting fallback cleanup"

  log "Stopping Backblaze processes (best-effort)"
  pkill -x bzbmenu 2>/dev/null || true
  pkill -x bztransmit 2>/dev/null || true
  pkill -x bzserv 2>/dev/null || true
  pkill -x bzfilelist 2>/dev/null || true
  sleep 2

  log "Unloading launchd items (best-effort)"
  launchctl bootout system /Library/LaunchDaemons/com.backblaze.* 2>/dev/null || true
  launchctl bootout gui/0 /Library/LaunchAgents/com.backblaze.* 2>/dev/null || true

  log "Removing Backblaze directories"
  rm -rf "/Library/Application Support/Backblaze" 2>/dev/null || true
  rm -rf "/Library/Backblaze.bzpkg" 2>/dev/null || true

  log "Removing Applications stubs"
  rm -rf "/Applications/Backblaze.app" 2>/dev/null || true
  rm -rf "/Applications/Backblaze Restore.app" 2>/dev/null || true
  rm -rf "/Applications/BackblazeRestore.app" 2>/dev/null || true

  log "Removing preference panes"
  rm -rf "/Library/PreferencePanes/BackblazeBackup.prefPane" 2>/dev/null || true
  rm -rf "/Library/PreferencePanes/Backblaze Settings Launcher.prefpane" 2>/dev/null || true

  log "Removing preference files"
  rm -f /Library/Preferences/com.backblaze.* 2>/dev/null || true
  rm -f /Library/LaunchDaemons/com.backblaze.* 2>/dev/null || true
  rm -f /Library/LaunchAgents/com.backblaze.* 2>/dev/null || true

  log "Removing per-user Backblaze data"
  for udir in /Users/*; do
    [[ -d "$udir" ]] || continue
    rm -f "$udir/Library/Preferences/com.backblaze."* 2>/dev/null || true
    rm -rf "$udir/Library/Application Support/Backblaze" 2>/dev/null || true
    rm -rf "$udir/Library/Application Support/BackblazeRestore" 2>/dev/null || true
    rm -rf "$udir/Library/Caches/Preferences/com.backblaze.Backblaze11" 2>/dev/null || true
    rm -rf "$udir/Library/Caches/com.backblaze.BackblazeRestore" 2>/dev/null || true
    rm -rf "$udir/Library/Logs/Backblaze" 2>/dev/null || true
    rm -rf "$udir/Library/Logs/BackblazeGUIInstaller" 2>/dev/null || true
    rm -rf "$udir/Library/Logs/BackblazeRestore" 2>/dev/null || true
    rm -rf "$udir/Library/Logs/BackblazeSilentInstaller" 2>/dev/null || true
    rm -f "$udir/Library/Logs/com.backblaze.bzuninstallerswift.log" 2>/dev/null || true
  done
}

if run_vendor_uninstall; then
  log "Vendor uninstall completed successfully"
else
  log "WARN: Vendor uninstall returned non-zero; continuing with fallback cleanup"
  fallback_cleanup
fi

if [[ -d "$BZPKG" ]]; then
  log "WARN: /Library/Backblaze.bzpkg still exists after uninstall attempt"
else
  log "OK: /Library/Backblaze.bzpkg removed"
fi

if pgrep -x bzserv >/dev/null 2>&1; then
  log "WARN: bzserv still running"
else
  log "OK: bzserv not running"
fi

log "RMM log file available at: ${RMM_LOG_FILE}"
log "=== DONE Backblaze uninstall ==="
exit 0
