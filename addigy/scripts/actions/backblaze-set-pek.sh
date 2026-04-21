#!/bin/bash
# backblaze-set-pek.sh
# Sets a new PEK (requires group auth + root)

set -euo pipefail

BZCLI="/Applications/Backblaze.app/Contents/MacOS/bzcli"
LOG_FILE="${LOG_FILE:-/var/log/backblaze_mdm_actions.log}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [bzcli][set-pek] $*" | tee -a "$LOG_FILE" ; }
die() { log "ERROR: $*"; exit 1; }

GROUP_ID="${4:-${BZ_GROUP_ID:-}}"
GROUP_TOKEN="${5:-${BZ_GROUP_TOKEN:-}}"
PEK_NEW="${6:-${BZ_PEK_NEW:-}}"

[[ "$(id -u)" -eq 0 ]] || die "Must run as root (Jamf runs scripts as root)."
[[ -x "$BZCLI" ]] || die "bzcli not found/executable at: $BZCLI"
[[ -n "$GROUP_ID" ]] || die "Missing GROUP_ID (Jamf param 4 or BZ_GROUP_ID)"
[[ -n "$GROUP_TOKEN" ]] || die "Missing GROUP_TOKEN (Jamf param 5 or BZ_GROUP_TOKEN)"
[[ -n "$PEK_NEW" ]] || die "Missing PEK_NEW (Jamf param 6 or BZ_PEK_NEW)"

AUTH_ARG="${GROUP_ID}:${GROUP_TOKEN}"

log "Pausing backup (best practice before PEK changes)…"
"$BZCLI" action --pause-backup >/dev/null 2>&1 || true

log "Setting PEK (requires auth)…"
"$BZCLI" action --group "$AUTH_ARG" --set-pek "$PEK_NEW" | tee -a "$LOG_FILE"

log "Triggering backup-now…"
"$BZCLI" action --backup-now >/dev/null 2>&1 || true

log "Verifying has_pek…"
HAS_PEK="$("$BZCLI" report -v /backup/installation/has_pek 2>/dev/null | tail -n 1 || true)"
log "has_pek=${HAS_PEK:-unknown}"

log "Done."
exit 0
