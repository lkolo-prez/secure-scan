#!/bin/bash
# ============================================================================
#  build-app.sh — buduje natywną SecureScan.app z silnika bash + frontendu Swift.
#  Wymaga tylko Xcode Command Line Tools (swiftc). Nie wymaga pełnego Xcode.
#  Wynik: dist/SecureScan.app (ad-hoc podpisana, gotowa do uruchomienia).
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
APP="$DIST/SecureScan.app"
CONTENTS="$APP/Contents"
VERSION="$(grep -m1 'VERSION=' "$ROOT/lib/core.sh" | sed 's/.*"\(.*\)".*/\1/')"
TARGET="${MACOS_TARGET:-arm64-apple-macos14.0}"

echo "==> SecureScan.app v$VERSION  (target: $TARGET)"

# 1. Czysty katalog wynikowy -------------------------------------------------
rm -rf "$DIST"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources/engine"

# 2. Kompilacja Swift --------------------------------------------------------
SDK="$(xcrun --sdk macosx --show-sdk-path)"
echo "==> Kompiluję (SDK: $(basename "$(dirname "$(dirname "$SDK")")"))…"
swiftc -sdk "$SDK" -target "$TARGET" -parse-as-library -O \
  "$ROOT/app/Sources/SecureScan/"*.swift \
  -o "$CONTENTS/MacOS/SecureScan"

# 3. Wbudowanie silnika bash (Resources/engine) ------------------------------
echo "==> Wbudowuję silnik skanujący…"
cp "$ROOT/secure-scan.sh" "$CONTENTS/Resources/engine/"
cp -R "$ROOT/lib" "$CONTENTS/Resources/engine/"
chmod +x "$CONTENTS/Resources/engine/secure-scan.sh" "$CONTENTS/Resources/engine/lib/"*.sh

# 4. Info.plist --------------------------------------------------------------
cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>SecureScan</string>
  <key>CFBundleIdentifier</key><string>com.securescan.app</string>
  <key>CFBundleName</key><string>SecureScan</string>
  <key>CFBundleDisplayName</key><string>SecureScan</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>MIT © 2026 lkolo-prez</string>
</dict></plist>
PLIST

# 5. Ad-hoc podpis (żeby Gatekeeper pozwolił uruchomić) ----------------------
echo "==> Podpisuję (ad-hoc)…"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1
codesign --verify --verbose "$APP" 2>&1 | sed 's/^/    /'

echo ""
echo "✅ Gotowe: $APP"
echo "   Uruchom:  open \"$APP\""
echo "   Zainstaluj: cp -R \"$APP\" /Applications/"
