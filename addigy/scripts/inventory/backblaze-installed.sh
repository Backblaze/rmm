#!/bin/bash
# Jamf Extension Attribute: Backblaze – Installed

if pgrep -x "bzserv" >/dev/null 2>&1; then
  echo "<result>Installed</result>"
else
  echo "<result>Not Installed</result>"
fi
