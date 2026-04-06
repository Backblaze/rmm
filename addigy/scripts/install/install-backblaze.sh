#!/bin/bash
# Backblaze Business Group Install (Addigy) — UAT
#
# Purpose:
#   UAT-focused installer that enrolls/signs-in devices to a Backblaze Business Group.
#   This script requires either group enrollment environment variables
#   or an installer JSON config for the advanced installer path.
#
# Addigy Inputs (environment variables):
#   BZ_GROUP_ID         = Backblaze Group ID            (required unless JSON config is used)
#   BZ_GROUP_TOKEN      = Backblaze Group Auth Token    (required unless JSON config is used)
#   BZ_EMAIL            = Backblaze Email               (required unless JSON config is used)
#   BZ_REGION           = Backblaze Region              (optional)
#   BZ_DMG_URL          = DMG URL override              (optional)
#   BZ_START_BACKUP     = Start backup after install    (optional; 1/true/yes to enable)
#   BZ_INSTALL_CFG_B64  = Installer JSON config (base64) (optional; preferred)
#   BZ_INSTALL_CFG_URL  = Installer JSON config URL      (optional; downloaded to /tmp)
#
# Defaults:
#   - Uses the public v10 installer DMG by default (UAT)
#   - Installs or silently upgrades if already installed
#   - Verifies bzserv is running (retry loop)
#
# Notes:
# - Addigy runs scripts as root.
# - Logs to stdout + /var/log/backblaze_addigy_install.log
# - Does NOT print tokens.

set -euo pipefail

#############################################
# LOGGING
#############################################
LOG_FILE="/var/log/backblaze_addigy_install.log"
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
BZ_START_BACKUP="${BZ_START_BACKUP:-""}"
BZ_INSTALL_CFG_B64="${BZ_INSTALL_CFG_B64:-""}"
BZ_INSTALL_CFG_URL="${BZ_INSTALL_CFG_URL:-""}"

# UAT default: public v10 build DMG (can be overridden by BZ_DMG_URL)
BZ_DMG_URL_DEFAULT="https://secure.backblaze.com/mac/install_backblaze.dmg"
BZ_DMG_URL="${BZ_DMG_URL:-$BZ_DMG_URL_DEFAULT}"

#############################################
# OPTIONAL: INSTALLER JSON CONFIG (v10 advanced installer)
#############################################
BZ_INSTALL_CFG_PATH="/tmp/backblaze_installer_config.json"
HAVE_INSTALL_CFG=0

#
# Prefer base64 content (avoids quoting/escaping issues)
if [[ -n "${BZ_INSTALL_CFG_B64:-}" ]]; then
  log "Installer JSON config provided via BZ_INSTALL_CFG_B64 environment variable."

  # Environment-provided values can sometimes include newlines/whitespace; normalize before decoding.
  BZ_INSTALL_CFG_B64_CLEAN="$(printf '%s' "$BZ_INSTALL_CFG_B64" | tr -d '\r\n \t')"

  if [[ -z "$BZ_INSTALL_CFG_B64_CLEAN" ]]; then
    log "ERROR: Installer JSON config (base64) was provided but is empty after normalization."
    exit 1
  fi

  # Decode base64 to JSON file. Prefer GNU-style --decode when available; fall back to macOS -D.
  if ! printf '%s' "$BZ_INSTALL_CFG_B64_CLEAN" | /usr/bin/base64 --decode > "$BZ_INSTALL_CFG_PATH" 2>/dev/null; then
    if ! printf '%s' "$BZ_INSTALL_CFG_B64_CLEAN" | /usr/bin/base64 -D > "$BZ_INSTALL_CFG_PATH" 2>/dev/null; then
      log "ERROR: Failed to base64-decode installer JSON config from BZ_INSTALL_CFG_B64."
      exit 1
    fi
  fi

  HAVE_INSTALL_CFG=1
elif [[ -n "${BZ_INSTALL_CFG_URL:-}" ]]; then
  log "Installer JSON config URL provided via BZ_INSTALL_CFG_URL environment variable."
  log "  URL: $BZ_INSTALL_CFG_URL"
  curl -fLsS --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 120 \
    "$BZ_INSTALL_CFG_URL" -o "$BZ_INSTALL_CFG_PATH"
  HAVE_INSTALL_CFG=1
fi

if [[ $HAVE_INSTALL_CFG -eq 1 ]]; then
  # Don't print the JSON; just confirm it exists, is non-empty, and looks like JSON.
  if [[ ! -s "$BZ_INSTALL_CFG_PATH" ]]; then
    log "ERROR: Installer JSON config file is empty at: $BZ_INSTALL_CFG_PATH"
    exit 1
  fi

  # Basic sanity check (no full JSON logging).
  if ! head -c 1 "$BZ_INSTALL_CFG_PATH" | grep -q '{'; then
    log "ERROR: Installer JSON config does not appear to be valid JSON (missing leading '{')."
    exit 1
  fi

  JSON_BYTES="$(/usr/bin/stat -f%z "$BZ_INSTALL_CFG_PATH" 2>/dev/null || echo 0)"
  log "Installer JSON config saved to: $BZ_INSTALL_CFG_PATH (${JSON_BYTES} bytes)"
fi

#############################################
# VALIDATION (UAT)
#############################################
# UAT requires either:
# - explicit group enrollment environment variables (BZ_GROUP_ID, BZ_GROUP_TOKEN, BZ_EMAIL), OR
# - a JSON config file for the advanced installer (-cfg)
if [[ $HAVE_INSTALL_CFG -eq 0 ]]; then
  if [[ -z "$BZ_GROUP_ID" || -z "$BZ_GROUP_TOKEN" || -z "$BZ_EMAIL" ]]; then
    log "ERROR: Missing required values for Business Group enrollment."
    log "  BZ_GROUP_ID='${BZ_GROUP_ID}'"
    log "  BZ_EMAIL='${BZ_EMAIL}'"
    log "Provide via BZ_GROUP_ID / BZ_GROUP_TOKEN / BZ_EMAIL, or provide installer JSON config via BZ_INSTALL_CFG_B64 or BZ_INSTALL_CFG_URL."
    exit 1
  fi
fi

#############################################
# INTERNAL CONSTANTS
#############################################
BZ_DMG_PATH="/tmp/backblaze_installer.dmg"
BZ_PLIST="/tmp/backblaze_hdiutil.plist"
BZ_MOUNTPOINT=""
# We do NOT hardcode a single app bundle path because DMG layouts can vary.
# We'll discover `bzinstall_mate` inside the mounted volume.
BZ_INSTALLER=""

#############################################
# CLEANUP
#############################################
cleanup() {
  log "Cleanup…"
  if [[ -n "${BZ_MOUNTPOINT}" && -d "${BZ_MOUNTPOINT}" ]]; then
    /usr/sbin/diskutil unmount force "${BZ_MOUNTPOINT}" >/dev/null 2>&1 || true
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

# NOTE: With `set -e`, a failing `hdiutil attach` can exit before the script captures useful output.
# Capture stdout/stderr and log it on failure.
set +e
ATTACH_PLIST_OUT="$(hdiutil attach -nobrowse -plist "$BZ_DMG_PATH" 2>&1)"
HDIUTIL_RC=$?
set -e

if [[ $HDIUTIL_RC -ne 0 ]]; then
  log "ERROR: hdiutil attach failed (rc=${HDIUTIL_RC})."
  log "ERROR: hdiutil output:"
  echo "$ATTACH_PLIST_OUT"
  log "ERROR: DMG details (ls -lh):"
  ls -lh "$BZ_DMG_PATH" || true
  exit 1
fi

# Persist the returned plist to disk for parsing below.
printf '%s\n' "$ATTACH_PLIST_OUT" > "$BZ_PLIST"

# Extract mount-point(s) from plist. PlistBuddy prints lines like:
#   mount-point = /Volumes/Backblaze Installer
# Grab all mount points, then pick the first existing directory.
MOUNT_POINTS="$(/usr/libexec/PlistBuddy -c "Print :system-entities" "$BZ_PLIST" 2>/dev/null | awk -F'= ' '/mount-point =/ {print $2}')"

if [[ -n "$MOUNT_POINTS" ]]; then
  while IFS= read -r mp; do
    if [[ -n "$mp" && -d "$mp" ]]; then
      BZ_MOUNTPOINT="$mp"
      break
    fi
  done <<< "$MOUNT_POINTS"
fi

 # Fallback: if we still can't find a mount point, dump what we parsed for troubleshooting.
# Do NOT call hdiutil attach again (that can create duplicate mounts like "Backblaze Installer 3").
if [[ -z "$BZ_MOUNTPOINT" ]]; then
  log "ERROR: mount point parse failed; got no valid /Volumes path from hdiutil plist output."
  log "DEBUG: Parsed mount-points (raw):"
  echo "$MOUNT_POINTS" || true
  log "DEBUG: First 60 lines of returned plist (if present):"
  sed -n '1,60p' "$BZ_PLIST" 2>/dev/null || true
  exit 1
fi

log "Mounted at: $BZ_MOUNTPOINT"

# Discover bzinstall_mate inside the mounted volume (Installer DMG)
# NOTE: If this is a Downloader DMG, it will typically contain BackblazeDownloader.app and NOT bzinstall_mate.
BZ_INSTALLER="$(/usr/bin/find "$BZ_MOUNTPOINT" -maxdepth 6 -type f -name "bzinstall_mate" -perm -111 2>/dev/null | /usr/bin/head -n 1)"

if [[ -z "${BZ_INSTALLER:-}" || ! -x "$BZ_INSTALLER" ]]; then
  log "ERROR: Installer binary 'bzinstall_mate' not found in mounted DMG at: $BZ_MOUNTPOINT"
  if /bin/ls -1 "$BZ_MOUNTPOINT" 2>/dev/null | grep -qi "BackblazeDownloader.app"; then
    log "HINT: This looks like a Downloader DMG (contains BackblazeDownloader.app). Use the Installer DMG (bzinstall-mac-10.x.x.xxxx.dmg) instead."
  fi
  log "Listing mount root for troubleshooting:"
  ls -la "$BZ_MOUNTPOINT" || true
  exit 1
fi

log "Found installer: $BZ_INSTALLER"

#############################################
# INSTALL OR UPGRADE
#############################################
rc=0

if pgrep -x "bzserv" >/dev/null 2>&1; then
  log "Backblaze already installed — performing silent upgrade…"
  set +e
  UPGRADE_OUT="$("$BZ_INSTALLER" --silentUpgrade 2>&1)"
  rc=$?
  set -e

  # Always log installer output for troubleshooting (may include benign version comparisons).
  if [[ -n "$UPGRADE_OUT" ]]; then
    echo "$UPGRADE_OUT" | tee -a "$LOG_FILE" >/dev/null
  fi

  # UAT safeguard: treat "installed version is newer than the installer" as a no-op success.
  # This can happen when testing a newer client against an older/incorrectly-versioned DMG.
  if [[ $rc -ne 0 ]] && echo "$UPGRADE_OUT" | grep -qi "installed version" && echo "$UPGRADE_OUT" | grep -qi "newer than the installer version"; then
    log "WARN: Installed client appears newer than the installer DMG; treating as no-op success."
    rc=0
  fi
else
  if [[ $HAVE_INSTALL_CFG -eq 1 ]]; then
    log "Fresh Backblaze Business Group install (advanced JSON config)."
  else
    log "Fresh Backblaze Business Group install for ${BZ_EMAIL}…"
  fi

  if [[ $HAVE_INSTALL_CFG -eq 1 ]]; then
    log "Running advanced installer with JSON config (-cfg)."
    set +e
    INSTALL_OUT="$("$BZ_INSTALLER" -cfg "$BZ_INSTALL_CFG_PATH" 2>&1)"
    rc=$?
    set -e

    # Always log installer output for troubleshooting
    if [[ -n "$INSTALL_OUT" ]]; then
      echo "$INSTALL_OUT" | tee -a "$LOG_FILE" >/dev/null
    fi
  else
    INSTALL_ARGS=(--createaccount_or_signinaccount
                  -emailAddress "$BZ_EMAIL"
                  -groupId "$BZ_GROUP_ID"
                  -groupAuthToken "$BZ_GROUP_TOKEN")

    if [[ -n "$BZ_REGION" ]]; then
      INSTALL_ARGS+=(-region "$BZ_REGION")
    fi

    set +e
    "$BZ_INSTALLER" "${INSTALL_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE" >/dev/null
    rc=${PIPESTATUS[0]}
    set -e
  fi
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

#############################################
# OPTIONAL: START/RESUME BACKUP (best-effort)
#############################################
# We cannot programmatically grant macOS privacy permissions (FDA, Location, etc.) here.
# Addigy privacy / profile configuration should be scoped separately.
# This section is best-effort and will not fail the install if the CLI command is unsupported.

normalize_bool() {
  # macOS ships Bash 3.2 by default; it does NOT support ${var,,} lowercase expansion.
  # Use `tr` to normalize to lowercase instead.
  local v
  v="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

BZTRANSMIT="/Library/Backblaze.bzpkg/bztransmit"

if normalize_bool "${BZ_START_BACKUP:-}"; then
  log "Start-backup requested (BZ_START_BACKUP=${BZ_START_BACKUP})."

  if [[ -x "$BZTRANSMIT" ]]; then
    # Determine which flags are supported by this client.
    HELP_OUT="$("$BZTRANSMIT" -help 2>&1 || true)"

    run_if_supported() {
      local flag="$1"
      if echo "$HELP_OUT" | grep -q "${flag}"; then
        log "Attempting: bztransmit ${flag}"
        "${BZTRANSMIT}" "${flag}" >/dev/null 2>&1 || true
        return 0
      fi
      return 1
    }

    # Most common: resume/unpause.
    run_if_supported "-resume" || run_if_supported "-unpause" || true

    # If the client supports an explicit backup trigger, try it.
    run_if_supported "-backupnow" || run_if_supported "-startbackup" || true

    log "Start-backup step completed (best-effort)."
  else
    log "WARN: bztransmit not found/executable at $BZTRANSMIT; skipping start-backup step."
  fi
else
  log "Start-backup not requested (set BZ_START_BACKUP=1 to enable)."
fi

if [[ -n "${BZ_GROUP_ID:-}" ]]; then
  log "Backblaze client installed and running. Group ID: $BZ_GROUP_ID"
else
  log "Backblaze client installed and running. Group ID: (configured via JSON)"
fi
log "=== Backblaze Business Group install completed successfully (UAT) ==="
exit 0
