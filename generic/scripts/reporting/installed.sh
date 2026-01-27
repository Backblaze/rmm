#!/bin/bash
set -euo pipefail

if pgrep -x "bzserv" >/dev/null 2>&1; then
  echo "Installed"
else
  echo "Not Installed"
fi
