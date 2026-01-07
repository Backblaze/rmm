#!/bin/bash
# Install Backblaze Business v10 (Jamf Pro)
# UAT / sandbox reference implementation

set -e

BACKBLAZE_APP="/Applications/Backblaze.app"
DMG_URL="https://f000.backblazeb2.com/file/b2-computer-backup-files/macos/downloader/bzdownloader-mac-10.0.0.1012.dmg"
DMG_PATH="/tmp/backblaze_v10.dmg"
MOUNT_POINT="/Volumes/Backblaze Installer"

echo "Starting Backblaze Business v10 installation..."

# Check if already installed
if [ -d "$BACKBLAZE_APP" ]; then
  echo "Backblaze already installed. Exiting."
  exit 0
fi

echo "Downloading Backblaze installer..."
curl -fsSL "$DMG_URL" -o "$DMG_PATH"

echo "Mounting installer DMG..."
hdiutil attach "$DMG_PATH" -nobrowse -quiet

echo "Running installer..."
"$MOUNT_POINT/Backblaze Installer.app/Contents/MacOS/bzinstall_mate" -nogui

echo "Cleaning up..."
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$DMG_PATH"

echo "Backblaze Business v10 installation completed successfully."
exit 0
