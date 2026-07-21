#!/bin/bash
# ============================================================================
#  scripts/security-audit.sh — self-check bezpieczeństwa repozytorium
#  by Aircloud — Łukasz Kołodziej
#  Uruchamia: shellcheck, skan sekretów, groźne wzorce, uprawnienia plików.
#  Kod wyjścia 0 = czysto.
# ============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FINDINGS=0
note()  { printf "  ✅ %s\n" "$1"; }
warn()  { printf "  ⚠️  %s\n" "$1"; }
fail()  { FINDINGS=$((FINDINGS+1)); printf "  ❌ %s\n" "$1"; }

SHELL_FILES="secure-scan.sh secure-scan.command build-app.sh install.sh $(ls lib/*.sh tests/*.sh scripts/*.sh 2>/dev/null)"

echo "▶ 1. ShellCheck (błędy blokują)"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S error -e SC1090,SC1091 $SHELL_FILES; then
    note "shellcheck: brak błędów"
  else
    fail "shellcheck zgłosił błędy (powyżej)"
  fi
  W="$(shellcheck -S warning -e SC1090,SC1091 $SHELL_FILES 2>&1 | grep -c '\(warning\)' || true)"
  [ "${W:-0}" -gt 0 ] && warn "shellcheck: $W ostrzeżeń (niekrytyczne)"
else
  warn "shellcheck niedostępny — pomijam (CI go uruchomi)"
fi

echo "▶ 2. Skan sekretów (klucze/tokeny)"
SECRET_RE='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z-]{10,}|gh[pousr]_[0-9A-Za-z]{30,}|AIza[0-9A-Za-z_-]{30,}'
if git ls-files 2>/dev/null | grep -qv '^$'; then TRACKED="$(git ls-files)"; else TRACKED="$(find . -type f -not -path './.git/*')"; fi
HITS="$(printf '%s\n' "$TRACKED" | grep -vE '\.(png|icns|dmg)$' | while read -r f; do
          [ -f "$f" ] && grep -HnE "$SECRET_RE" "$f" 2>/dev/null; done)"
if [ -z "$HITS" ]; then note "brak wyciekających sekretów w wersjonowanych plikach"; else fail "możliwy sekret:"; printf '%s\n' "$HITS"; fi

echo "▶ 3. Groźne wzorce w silniku (musi być read-only)"
if grep -REn 'rm +-rf +\$|(curl|wget)[^|]*https?://[^|]*\|[[:space:]]*(ba)?sh|eval +\$[0-9@*]' lib secure-scan.sh 2>/dev/null; then
  fail "groźny wzorzec w silniku (rm -rf \$var / pobieranie|powłoka / eval \$args)"
else
  note "silnik bez groźnych wzorców (read-only)"
fi

echo "▶ 4. Uprawnienia: brak plików zapisywalnych dla wszystkich"
WW="$(find . -type f -not -path './.git/*' -perm -0002 2>/dev/null)"
if [ -z "$WW" ]; then note "brak plików world-writable"; else fail "pliki world-writable:"; printf '%s\n' "$WW"; fi

echo "▶ 5. Skrypty wykonywalne mają shebang"
for f in secure-scan.sh build-app.sh install.sh tests/run-tests.sh scripts/security-audit.sh; do
  [ -f "$f" ] || continue
  head -1 "$f" | grep -q '^#!' && note "shebang OK: $f" || fail "brak shebang: $f"
done

echo ""
echo "════════════════════════════════════════"
if [ "$FINDINGS" -eq 0 ]; then
  echo "✅ Audyt bezpieczeństwa: czysto."
else
  echo "❌ Audyt bezpieczeństwa: $FINDINGS ustaleń do naprawy."
  exit 1
fi
