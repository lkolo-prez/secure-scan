#!/bin/bash
# ============================================================================
#  make-dmg.sh — pakuje SecureScan.app do dystrybucyjnego .dmg
#  by Aircloud — Łukasz Kołodziej
#  Wynik: dist/SecureScan.dmg (przeciągnij aplikację do Applications).
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/dist"
APP="$DIST/SecureScan.app"
VERSION="$(grep -m1 'VERSION=' "$ROOT/lib/core.sh" | sed 's/.*"\(.*\)".*/\1/')"
DMG="$DIST/SecureScan-$VERSION.dmg"

# 1. Zbuduj aplikację, jeśli brak
[ -d "$APP" ] || "$ROOT/build-app.sh"

# 2. Przygotuj zawartość obrazu
STAGE="$DIST/_dmg"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# 3. Zbuduj skompresowany .dmg
rm -f "$DMG"
hdiutil create -volname "SecureScan by Aircloud" -srcfolder "$STAGE" \
  -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

SIZE="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo "✅ Gotowe: $DMG ($SIZE)"
echo "   Instalacja: otwórz .dmg i przeciągnij SecureScan do Applications."
