cat > jamf/scripts/extension-attributes/backblaze-client-version.sh <<'EOF'
#!/bin/bash
find_bzcli() {
  if command -v bzcli >/dev/null 2>&1; then
    command -v bzcli
    return 0
  fi
  for p in \
    "/usr/local/bin/bzcli" \
    "/opt/homebrew/bin/bzcli" \
    "/usr/bin/bzcli" \
    "/Library/Backblaze/bzcli"
  do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

if ! BZCLI="$(find_bzcli)"; then
  echo "<result>bzcli not found</result>"
  exit 0
fi

VAL="$("$BZCLI" report -v /backup/installation/version 2>/dev/null | tr -d '\r')"
echo "<result>${VAL:-Unknown}</result>"
EOF
chmod +x jamf/scripts/extension-attributes/backblaze-client-version.sh