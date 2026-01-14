#!/bin/bash
# Backblaze (bzcli) reporting: Host GUID (HGUID)
# Output: plain text (client-friendly)

set -euo pipefail

BZCLI_CANONICAL="/Applications/Backblaze.app/Contents/MacOS/bzcli"

find_bzcli() {
  if [[ -x "$BZCLI_CANONICAL" ]]; then
    echo "$BZCLI_CANONICAL"; return 0
  fi
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli; return 0
  fi
  for p in \
    "/usr/local/bin/bzcli" \
    "/opt/homebrew/bin/bzcli" \
    "/usr/bin/bzcli" \
    "/Library/Backblaze/bzcli"; do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

strip_quotes() {
  # trims leading/trailing whitespace and optional surrounding quotes
  sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//'
}

if ! BZCLI="$(find_bzcli)"; then
  echo "bzcli not found"
  exit 0
fi

VAL="$($BZCLI report -v /backup/installation/hguid 2>/dev/null | tr -d '\r' | strip_quotes)"
echo "${VAL:-Unknown}"#!/bin/bash
# Backblaze (bzcli) reporting: Status Summary
# Output: plain text (client-friendly)

set -euo pipefail

BZCLI_CANONICAL="/Applications/Backblaze.app/Contents/MacOS/bzcli"

find_bzcli() {
  if [[ -x "$BZCLI_CANONICAL" ]]; then
    echo "$BZCLI_CANONICAL"; return 0
  fi
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli; return 0
  fi
  for p in \
    "/usr/local/bin/bzcli" \
    "/opt/homebrew/bin/bzcli" \
    "/usr/bin/bzcli" \
    "/Library/Backblaze/bzcli"; do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

strip_quotes() {
  # trims leading/trailing whitespace and optional surrounding quotes
  sed -E 's/^[[:space:]]*"?//; s/"?[[:space:]]*$//'
}

if ! BZCLI="$(find_bzcli)"; then
  echo "bzcli not found"
  exit 0
fi

VAL="$($BZCLI report -v /backup/status/summary 2>/dev/null | tr -d '\r' | strip_quotes)"
echo "${VAL:-Unknown}"# Generic Backblaze Integration

This repository contains scripts and documentation for integrating Backblaze Computer Backup in a generic manner.

## Repository Structure

```text
generic/
├── README.md
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── install.md
│   └── reporting.md
└── scripts/
    ├── actions/
    │   ├── backup-now.sh
    │   ├── pause-backup.sh
    │   └── resume-backup.sh
    ├── install/
    │   └── install-backblaze.sh
    └── reporting/
        ├── client-version.sh
        ├── installed.sh
        ├── status-summary.sh
        ├── last-backup-iso8601.sh
        └── hguid.sh
```

## Documentation

Start here: `generic/docs/README.md`

- Actions: `generic/docs/actions.md`
- Install: `generic/docs/install.md`
- Reporting: `generic/docs/reporting.md`# Generic Backblaze Integration

This repository contains scripts and documentation for integrating Backblaze Computer Backup in a generic manner.

---

## Repository layout (Generic)

```text
generic/
├── README.md
├── docs/
│   ├── README.md
│   ├── actions.md
│   ├── install.md
│   └── reporting.md
└── scripts/
    ├── actions/
    │   ├── backup-now.sh
    │   ├── pause-backup.sh
    │   └── resume-backup.sh
    ├── install/
    │   └── install-backblaze.sh
    └── reporting/
        ├── client-version.sh
        ├── installed.sh
        ├── status-summary.sh
        ├── last-backup-iso8601.sh
        └── hguid.sh
```

---

## Documentation

- Actions: `actions.md`
- Install: `install.md`
- Reporting: `reporting.md`
