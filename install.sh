#!/bin/bash
# Instalator secure-scan — pobiera skrypt i instaluje do ~/.local/bin
# Użycie: curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/install.sh | bash
set -euo pipefail

RAW="https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/secure-scan.sh"
DEST_DIR="${HOME}/.local/bin"
DEST="${DEST_DIR}/secure-scan"

echo "==> Instaluję secure-scan do ${DEST}"
mkdir -p "$DEST_DIR"
curl -fsSL "$RAW" -o "$DEST"
chmod +x "$DEST"

echo "==> Gotowe."
case ":$PATH:" in
  *":$DEST_DIR:"*) echo "    Uruchom:  secure-scan" ;;
  *) echo "    Dodaj do PATH:  export PATH=\"\$HOME/.local/bin:\$PATH\""
     echo "    Lub uruchom:    $DEST" ;;
esac
