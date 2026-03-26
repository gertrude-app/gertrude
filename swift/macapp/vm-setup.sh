#!/usr/bin/env bash
set -euo pipefail

for i in $(seq 1 30); do
  [ -f "/Volumes/My Shared Files/build/Gertrude.app/Contents/MacOS/Gertrude" ] && break
  sleep 2
done
sleep 3
sudo cp -rf "/Volumes/My Shared Files/build/Gertrude.app" /Applications/

sudo -u franny defaults delete com.netrivet.gertrude.app 2>/dev/null || true
sudo rm -rf /Users/franny/Library/Application\ Support/Gertrude
sudo find /Users/franny/Library/Group\ Containers -name "*com.netrivet.gertrude.group" -exec rm -rf {} + 2>/dev/null || true

defaults delete com.netrivet.gertrude.app 2>/dev/null || true
rm -rf ~/Library/Application\ Support/Gertrude
find ~/Library/Group\ Containers -name "*com.netrivet.gertrude.group" -exec rm -rf {} + 2>/dev/null || true

sync
echo "✓ app installed and gertrude state wiped"
