#!/bin/bash
# Backblaze Uninstall (Addigy)
# Calls the official Backblaze uninstaller from the installed B1 client package.
# Safe and idempotent for Addigy/RMM usage.

set -euo pipefail

LOG_FILE="/var/log/backblaze_mdm_uninstall.log"
RMM_LOG_DIR="/Library/Logs/BackblazeSilentInstaller"
RMM_LOG_FILE="${RMM_LOG_DIR}/rmm.log"
OFFICIAL_UNINSTALLER="/Library/Backblaze.bzpkg/UninstallBackblaze.app/Contents/Resources/bzuninstaller.sh"
BZPKG="/Library/Backblaze.bzpkg"
BACKBLAZE_APP="/Applications/Backblaze.app"

mkdir -p "$RMM_LOG_DIR"
touch "$LOG_FILE" "$RMM_LOG_FILE"
chmod 644 "$LOG_FILE" "$RMM_LOG_FILE" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE" "$RMM_LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [backblaze][uninstall][addigy] $*"; }

log "=== START Backblaze uninstall (Addigy) ==="

if [[ "${EUID}" -ne 0 ]]; then
  log "ERROR: must run as root"
  exit 1
fi

if [[ ! -d "$BZPKG" ]]; then
  log "Backblaze is not installed; nothing to uninstall"
  log "RMM log file available at: ${RMM_LOG_FILE}"
  log "=== DONE Backblaze uninstall (Addigy) ==="
  exit 0
fi

if [[ ! -x "$OFFICIAL_UNINSTALLER" ]]; then
  log "ERROR: official Backblaze uninstaller not found or not executable at: $OFFICIAL_UNINSTALLER"
  log "RMM log file available at: ${RMM_LOG_FILE}"
  exit 1
fi

log "Calling official Backblaze uninstaller: $OFFICIAL_UNINSTALLER"
"$OFFICIAL_UNINSTALLER"
uninstall_exit_code=$?
log "Official Backblaze uninstaller exit code: $uninstall_exit_code"

if [[ "$uninstall_exit_code" -ne 0 ]]; then
  log "ERROR: official Backblaze uninstaller failed"
  log "RMM log file available at: ${RMM_LOG_FILE}"
  exit "$uninstall_exit_code"
fi

log "Verifying uninstall result"

verification_failed=0

if pgrep -x bzserv >/dev/null 2>&1; then
  log "WARN: bzserv is still running after uninstall"
  verification_failed=1
else
  log "OK: bzserv is not running"
fi

if [[ -d "$BZPKG" ]]; then
  log "WARN: $BZPKG still exists after uninstall"
  verification_failed=1
else
  log "OK: $BZPKG removed"
fi

if [[ -d "$BACKBLAZE_APP" ]]; then
  log "WARN: $BACKBLAZE_APP still exists after uninstall"
  verification_failed=1
else
  log "OK: $BACKBLAZE_APP removed"
fi

log "RMM log file available at: ${RMM_LOG_FILE}"

if [[ "$verification_failed" -ne 0 ]]; then
  log "=== DONE Backblaze uninstall (Addigy) with verification warnings ==="
  exit 2
fi

log "=== DONE Backblaze uninstall (Addigy) ==="
exit 0
