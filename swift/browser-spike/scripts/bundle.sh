#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

CONFIG="${1:-debug}"
APP="$ROOT/dist/BrowserSpike.app"

echo "[bundle] swift build --configuration $CONFIG"
swift build --configuration "$CONFIG" --product BrowserSpike --product PolicyStub

echo "[bundle] assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/$CONFIG/BrowserSpike" "$APP/Contents/MacOS/BrowserSpike"
cp ".build/$CONFIG/PolicyStub"  "$APP/Contents/MacOS/PolicyStub"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

xattr -cr "$APP" || true
codesign --force --deep --sign - "$APP"

echo "[bundle] LaunchServices register"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$APP" || true

echo "[bundle] done: $APP"
echo "  open '$APP'                 # launch"
echo "  open -b com.gertrude.browser-spike https://example.com   # via bundle id"
