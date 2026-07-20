#!/bin/bash
# Instalator secure-scan / secure-scan installer
# Klonuje repo do ~/.local/share i tworzy symlink w ~/.local/bin.
# Usage: curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/install.sh | bash
set -euo pipefail

REPO="https://github.com/lkolo-prez/secure-scan.git"
DEST="${HOME}/.local/share/secure-scan"
BIN_DIR="${HOME}/.local/bin"
BIN="${BIN_DIR}/secure-scan"

echo "==> secure-scan installer"
mkdir -p "$BIN_DIR" "$(dirname "$DEST")"

if [ -d "$DEST/.git" ]; then
  echo "    Aktualizuję / Updating ($DEST)…"
  git -C "$DEST" pull --ff-only
else
  echo "    Klonuję / Cloning → $DEST"
  git clone --depth 1 "$REPO" "$DEST"
fi

ln -sf "$DEST/secure-scan.sh" "$BIN"
chmod +x "$DEST/secure-scan.sh" "$DEST/secure-scan.command" "$DEST"/lib/*.sh 2>/dev/null || true

echo "==> Gotowe / Done."
case ":$PATH:" in
  *":$BIN_DIR:"*) echo "    Uruchom / Run:  secure-scan" ;;
  *) echo "    Dodaj do PATH / Add to PATH:  export PATH=\"\$HOME/.local/bin:\$PATH\""
     echo "    Lub / Or:  $BIN" ;;
esac
