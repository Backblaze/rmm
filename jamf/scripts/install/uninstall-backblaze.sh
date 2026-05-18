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

#!/bin/bash
# Backblaze Uninstall (Jamf Pro)
# Safe, idempotent uninstall with logging.
# Based on the official Backblaze uninstall cleanup flow, adapted for Jamf/MDM execution.

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
BZBMENU_NAME="com.backblaze.bzbmenu"
BZBMENU_PLIST="/Library/LaunchAgents/com.backblaze.bzbmenu.plist"
BZSERV_NAME="com.backblaze.bzserv"
BZSERV_PLIST="/Library/LaunchDaemons/com.backblaze.bzserv.plist"

get_parent_path() {
  local dir_path
  dir_path="$(dirname "$1")"
  dirname "$dir_path"
}

REMOVE_FROM_DOCK_PATH="$(get_parent_path "$0")/MacOS/removeFromDock"

remove_from_dock() {
  local console_user="$1"
  local current_user="$2"

  if [[ "$current_user" == "$console_user" ]]; then
    log "Removing Backblaze from Dock for console user: $current_user"

    if [[ -f "$REMOVE_FROM_DOCK_PATH" ]]; then
      local user_home
      user_home="$(/usr/bin/dscl /Local/Default read /Users/"$current_user" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"

      if [[ -n "$user_home" ]]; then
        /usr/bin/su -m "$current_user" -c "'$REMOVE_FROM_DOCK_PATH' -userHome '$user_home'" >/dev/null 2>&1 || true
      else
        log "WARN: could not determine home directory for $current_user"
      fi
    else
      log "removeFromDock helper not found at: $REMOVE_FROM_DOCK_PATH"
    fi
  fi
}

if [[ ! -d "$BZPKG" ]]; then
  log "Backblaze is not installed; nothing to uninstall"
  log "=== DONE Backblaze uninstall ==="
  exit 0
fi

log "Backblaze is installed. Removing Backblaze-related files and services."

log "Forgetting Backblaze package receipts"
while IFS= read -r package_id; do
  [[ -n "$package_id" ]] || continue
  log "Forgetting package receipt: $package_id"
  /usr/sbin/pkgutil --forget "$package_id" >/dev/null 2>&1 || true
done < <(/usr/sbin/pkgutil --pkgs | /usr/bin/grep -i backblaze || true)

console_user="$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')"
log "Console user detected: ${console_user:-none}"

log "Stopping and unloading per-user Backblaze menu agents"
while IFS= read -r user_name; do
  [[ -n "$user_name" ]] || continue

  home_dir="$(/usr/bin/dscl /Local/Default read /Users/"$user_name" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
  if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
    log "Skipping user $user_name; home directory not found"
    continue
  fi

  log "Processing user: $user_name ($home_dir)"

  /usr/bin/su -m "$user_name" -c "/bin/launchctl stop $BZBMENU_NAME" >/dev/null 2>&1 || true
  /usr/bin/su -m "$user_name" -c "/bin/launchctl unload '$home_dir$BZBMENU_PLIST'" >/dev/null 2>&1 || true
  /bin/rm -f "$home_dir$BZBMENU_PLIST" >/dev/null 2>&1 || true

  log "Removing user logs, preferences, caches, and restore data for $user_name"
  /bin/rm -fr "$home_dir/Library/Logs/Backblaze" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Logs/BackblazeGUIInstaller" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Logs/BackblazeRestore" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Logs/BackblazeSilentInstaller" >/dev/null 2>&1 || true
  /bin/rm -f  "$home_dir/Library/Logs/com.backblaze.bzuninstallerswift.log" >/dev/null 2>&1 || true

  /bin/rm -f "$home_dir/Library/Preferences/com.backblaze.Backblaze.plist" >/dev/null 2>&1 || true
  /bin/rm -f "$home_dir/Library/Preferences/com.backblaze.bzbmenu.plist" >/dev/null 2>&1 || true
  /bin/rm -f "$home_dir/Library/Preferences/com.backblaze."* >/dev/null 2>&1 || true

  /bin/rm -fr "$home_dir/Library/Caches/Preferences/com.backblaze.Backblaze11" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Caches/com.backblaze.BackblazeRestore" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Application Support/Backblaze" >/dev/null 2>&1 || true
  /bin/rm -fr "$home_dir/Library/Application Support/BackblazeRestore" >/dev/null 2>&1 || true
  /bin/rm -f  "$home_dir/Library/Preferences/com.backblaze.BackblazeRestore.plist" >/dev/null 2>&1 || true

  if [[ -n "${console_user:-}" ]]; then
    remove_from_dock "$console_user" "$user_name"
  fi

done < <(/usr/bin/dscl /Local/Default list /Users UniqueID | /usr/bin/awk '$2 > 500 {print $1}')

log "Stopping Backblaze processes"
/usr/bin/killall -9 bzbmenu >/dev/null 2>&1 || true
/usr/bin/killall -9 bzserv >/dev/null 2>&1 || true
/usr/bin/killall -9 bztransmit >/dev/null 2>&1 || true
/usr/bin/killall -9 bzfilelist >/dev/null 2>&1 || true
/usr/bin/killall -9 Backblaze11 >/dev/null 2>&1 || true
/usr/bin/killall -9 BackblazeRestore >/dev/null 2>&1 || true

log "Unloading and removing Backblaze launchd items"
/bin/launchctl unload "$BZSERV_PLIST" >/dev/null 2>&1 || true
/bin/launchctl bootout system "$BZSERV_PLIST" >/dev/null 2>&1 || true
/bin/rm -f "$BZSERV_PLIST" >/dev/null 2>&1 || true
/bin/rm -f /Library/LaunchDaemons/com.backblaze.* >/dev/null 2>&1 || true
/bin/rm -f /Library/LaunchAgents/com.backblaze.* >/dev/null 2>&1 || true

log "Closing System Settings / System Preferences if open"
/usr/bin/killall -9 "System Preferences" >/dev/null 2>&1 || true
/usr/bin/killall -9 "System Settings" >/dev/null 2>&1 || true

log "Removing Backblaze Preference Panes"
/bin/rm -rf "/Library/PreferencePanes/BackblazeBackup.prefPane" >/dev/null 2>&1 || true
/bin/rm -rf "/Library/PreferencePanes/Backblaze Settings Launcher.prefpane" >/dev/null 2>&1 || true

log "Removing Backblaze applications"
/bin/rm -rf "/Applications/Backblaze.app" >/dev/null 2>&1 || true
/bin/rm -rf "/Applications/BackblazeRestore.app" >/dev/null 2>&1 || true
/bin/rm -rf "/Applications/Backblaze Restore.app" >/dev/null 2>&1 || true

log "Removing Backblaze system data and logs"
/bin/rm -rf "/Library/Application Support/Backblaze" >/dev/null 2>&1 || true
/bin/rm -rf "$BZPKG" >/dev/null 2>&1 || true
/bin/rm -fr "/Library/Logs/BackblazeSilentInstaller" >/dev/null 2>&1 || true
/bin/rm -f /Library/Preferences/com.backblaze.* >/dev/null 2>&1 || true

if pgrep -x bzserv >/dev/null 2>&1; then
  log "WARN: bzserv still running after uninstall cleanup"
else
  log "OK: bzserv not running"
fi

if [[ -d "$BZPKG" ]]; then
  log "WARN: $BZPKG still exists after uninstall cleanup"
else
  log "OK: $BZPKG removed"
fi

log "=== DONE Backblaze uninstall ==="
exit 0