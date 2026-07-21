#!/bin/bash
# lib/protect.sh — ochrona sieci: blokowanie groźnych domen w /etc/hosts.
# by Aircloud — Łukasz Kołodziej.  Sourced by secure-scan.sh.
# Zarządzany blok jest oznaczony markerami i w pełni odwracalny (--unprotect).

PROTECT_START="# >>> secure-scan blocklist >>>"
PROTECT_END="# <<< secure-scan blocklist <<<"
HOSTS="/etc/hosts"
# Renomowane, utrzymywane źródło (reklamy + malware). Można nadpisać SECURE_SCAN_BLOCKLIST_URL.
PROTECT_SOURCE="${SECURE_SCAN_BLOCKLIST_URL:-https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts}"
PROTECT_SEED="$(dirname "${BASH_SOURCE[0]}")/blocklist-seed.txt"

# Liczba zablokowanych domen w zarządzanym bloku.
protect_count() {
  awk -v s="$PROTECT_START" -v e="$PROTECT_END" '
    $0==s {f=1; next} $0==e {f=0} f && /^0\.0\.0\.0[ \t]/ {c++} END {print c+0}' "$HOSTS" 2>/dev/null
}

protect_active() { [ "$(protect_count)" -gt 0 ] 2>/dev/null; }

# Buduje listę „0.0.0.0 domena" do pliku $1 (pobranie + fallback seed).
_protect_build() {
  local out="$1" tmp; tmp="$(mktemp)"
  if curl -fsSL --max-time 25 "$PROTECT_SOURCE" 2>/dev/null \
      | grep -E '^(0\.0\.0\.0|127\.0\.0\.1)[ \t]+[A-Za-z0-9.-]+' \
      | awk '{print "0.0.0.0 "$2}' > "$tmp" 2>/dev/null; then :; fi
  # dołącz seed (zawsze)
  if [ -f "$PROTECT_SEED" ]; then
    grep -vE '^\s*#|^\s*$' "$PROTECT_SEED" | awk '{print "0.0.0.0 "$1}' >> "$tmp"
  fi
  grep -vE 'localhost|broadcasthost|^0\.0\.0\.0 0\.0\.0\.0' "$tmp" | sort -u > "$out"
  rm -f "$tmp"
  [ -s "$out" ]
}

# Usuwa zarządzany blok z /etc/hosts (na stdout wypisuje nową zawartość).
_protect_strip() {
  awk -v s="$PROTECT_START" -v e="$PROTECT_END" '
    $0==s {skip=1} skip && $0==e {skip=0; next} !skip {print}' "$HOSTS"
}

# Instaluje/aktualizuje blocklistę (wymaga root; z CLI poprzedzone sudo -v).
protect_install() {
  local list base new; list="$(mktemp)"; base="$(mktemp)"; new="$(mktemp)"
  echo "==> $(L 'Buduję listę blokowanych domen…' 'Building blocklist…')"
  if ! _protect_build "$list"; then
    echo "   ❌ $(L 'Nie udało się zbudować listy.' 'Failed to build blocklist.')"; rm -f "$list" "$base" "$new"; return 1
  fi
  local n; n="$(grep -c . "$list")"
  _protect_strip > "$base"
  {
    cat "$base"
    echo ""
    echo "$PROTECT_START"
    echo "# $(date '+%Y-%m-%d %H:%M') — $n $(L 'domen; usuń: secure-scan --unprotect' 'domains; remove: secure-scan --unprotect')"
    cat "$list"
    echo "$PROTECT_END"
  } > "$new"
  if printf '%s\n' "$(cat "$new")" | sudo tee "$HOSTS" >/dev/null 2>&1; then
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    echo "   ✅ $(L 'Zablokowano' 'Blocked') $n $(L 'domen. DNS odświeżony.' 'domains. DNS flushed.')"
  else
    echo "   ❌ $(L 'Brak uprawnień do zapisu /etc/hosts.' 'No permission to write /etc/hosts.')"; rm -f "$list" "$base" "$new"; return 1
  fi
  rm -f "$list" "$base" "$new"
}

protect_remove() {
  local new; new="$(mktemp)"
  _protect_strip > "$new"
  if printf '%s' "$(cat "$new")" | sudo tee "$HOSTS" >/dev/null 2>&1; then
    sudo dscacheutil -flushcache 2>/dev/null
    sudo killall -HUP mDNSResponder 2>/dev/null
    echo "   ✅ $(L 'Ochrona sieci wyłączona, /etc/hosts przywrócony.' 'Web protection removed, /etc/hosts restored.')"
  else
    echo "   ❌ $(L 'Brak uprawnień.' 'No permission.')"; rm -f "$new"; return 1
  fi
  rm -f "$new"
}

# Wywoływane z secure-scan.sh dla --protect / --unprotect.
run_protect() {
  echo "🛡️  $(L 'Ochrona sieci — blokada groźnych domen' 'Web protection — block malicious domains')"
  if ! sudo -v 2>/dev/null; then echo "   ❌ $(L 'Wymaga sudo.' 'Requires sudo.')"; return 1; fi
  protect_install
  echo "   $(L 'Weryfikacja:' 'Verify:') secure-scan --only network"
}

run_unprotect() {
  echo "🛡️  $(L 'Wyłączam ochronę sieci' 'Disabling web protection')"
  if ! sudo -v 2>/dev/null; then echo "   ❌ $(L 'Wymaga sudo.' 'Requires sudo.')"; return 1; fi
  protect_remove
}
