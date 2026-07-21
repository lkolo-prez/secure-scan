#!/bin/bash
# ============================================================================
#  tests/run-tests.sh — zestaw testów secure-scan (czysty bash, bez zależności)
#  by Aircloud — Łukasz Kołodziej
#  Uruchom:  bash tests/run-tests.sh      (kod wyjścia 0 = wszystko przeszło)
# ============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/lib"
PASS=0; FAIL=0; FAILED=""

ok()  { PASS=$((PASS+1)); printf "  ✅ %s\n" "$1"; }
bad() { FAIL=$((FAIL+1)); FAILED="$FAILED\n   - $1"; printf "  ❌ %s\n" "$1"; }
assert_eq()       { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (oczekiwano '$2', było '$3')"; fi; }
assert_contains() { case "$3" in *"$2"*) ok "$1";; *) bad "$1 (brak '$2')";; esac; }
assert_absent()   { case "$3" in *"$2"*) bad "$1 (niespodziewane '$2')";; *) ok "$1";; esac; }
assert_true()     { local n="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$n"; else bad "$n"; fi; }
reset_state() { EARNED=0; POSSIBLE=0; N_PASS=0; N_WARN=0; N_FAIL=0; N_INFO=0
                CAT_POSSIBLE=0; CAT_EARNED=0; JSON="["; SECTIONS=""; CAT_NAMES=""; }

MODE="test"; LANG_SEL="pl"; NOW="test"
# shellcheck source=/dev/null
source "$LIB/core.sh"

echo "▶ 1. Framework: i18n L()"
assert_eq "L() zwraca PL" "tak" "$(LANG_SEL=pl L 'tak' 'yes')"
assert_eq "L() zwraca EN" "yes" "$(LANG_SEL=en L 'tak' 'yes')"

echo "▶ 2. Framework: punktacja add_check (przyrostowo)"
reset_state; begin_cat "T" "x"; add_check "p" PASS 10 "d" ""
assert_eq "PASS: +20 pkt"          "20" "$EARNED"
assert_eq "PASS: possible=20"      "20" "$POSSIBLE"
reset_state; begin_cat "T" "x"; add_check "w" WARN 10 "d" ""
assert_eq "WARN: +10 pkt (połowa)" "10" "$EARNED"
reset_state; begin_cat "T" "x"; add_check "f" FAIL 10 "d" ""
assert_eq "FAIL: +0 pkt"           "0"  "$EARNED"
reset_state; begin_cat "T" "x"; add_check "i" INFO 5 "d" ""
assert_eq "INFO: possible=0 (nie liczone)" "0" "$POSSIBLE"
assert_eq "INFO: earned=0"                 "0" "$EARNED"

echo "▶ 3. Framework: wynik i ocena"
reset_state; begin_cat "T" "x"
add_check "p" PASS 10 "d" ""; add_check "w" WARN 10 "d" ""; add_check "f" FAIL 10 "d" ""; add_check "i" INFO 0 "d" ""
finalize_score
assert_eq "SCORE = 30/60 = 50" "50" "$SCORE"
assert_contains "GRADE(50)=Słaby" "Słaby" "$GRADE"
assert_eq "N_INFO policzone" "1" "$N_INFO"

echo "▶ 4. Framework: escapowanie JSON (adversarial: backslash, cudzysłów)"
reset_state; begin_cat "Cat" "x"
add_check 'Proc "X"' INFO 0 'ścieżka Code\x20Helper i "cudzysłów" oraz\nkoniec' ""
WRAPPED="{\"checks\":${JSON%,}]}"
if command -v python3 >/dev/null 2>&1; then
  if printf '%s' "$WRAPPED" | python3 -c "import json,sys; json.loads(sys.stdin.read())" 2>/dev/null; then
    ok "JSON z \\x20 i cudzysłowami jest poprawny"
  else bad "JSON z danych z backslashami NIE parsuje się"; fi
else
  assert_contains "JSON escapuje cudzysłów" '\"' "$JSON"
fi

echo "▶ 5. CLI: --version / --help"
assert_contains "--version = 3.x" "secure-scan 3" "$(bash "$ROOT/secure-scan.sh" --version)"
assert_contains "--help ma Usage"  "Usage"        "$(bash "$ROOT/secure-scan.sh" --help)"

echo "▶ 6. CLI: --json poprawny (moduł files)"
J="$(bash "$ROOT/secure-scan.sh" --only files --json 2>/dev/null)"
assert_contains "JSON: tool=secure-scan" '"tool":"secure-scan"' "$J"
assert_contains "JSON: pole score"        '"score":'            "$J"
if command -v python3 >/dev/null 2>&1; then
  if printf '%s' "$J" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); exit(0 if d['checks'] else 1)"; then
    ok "JSON (files) parsuje się i ma kontrole"
  else bad "JSON (files) nie parsuje się"; fi
fi

echo "▶ 7. CLI: dwujęzyczność"
JE="$(bash "$ROOT/secure-scan.sh" --only files --lang en --json 2>/dev/null)"
assert_contains "EN: lang=en"           '"lang":"en"'    "$JE"
assert_contains "EN: nazwa po angielsku" 'File Integrity' "$JE"

echo "▶ 8. CLI: --only ogranicza moduły"
JO="$(bash "$ROOT/secure-scan.sh" --only network --json 2>/dev/null)"
assert_contains "only network: kategoria sieci" 'Aktywność sieciowa' "$JO"
assert_absent   "only network: bez FileVault"   'FileVault'          "$JO"

echo "▶ 9. Moduły: każdy zwraca kontrole bez błędu"
for mod in core malware browser perf network files downloads; do
  n="$(bash "$ROOT/secure-scan.sh" --only "$mod" --json 2>/dev/null | grep -o '"name":' | wc -l | tr -d ' ')"
  if [ "${n:-0}" -ge 1 ]; then ok "moduł $mod → $n kontroli"; else bad "moduł $mod: 0 kontroli"; fi
done

echo "▶ 10. Remediacja: bezpieczna (pomija gdy już OK, bez sudo)"
# shellcheck source=/dev/null
source "$LIB/remediate.sh"
assert_true "run_fix zdefiniowane"  declare -F run_fix
assert_true "fix_step zdefiniowane" declare -F fix_step
OUT="$(AUTO_YES=1 fix_step "t" "true" "echo NIE_POWINNO" 2>&1)"
assert_absent "fix_step nie wykonuje gdy 'już bezpieczne'" "NIE_POWINNO" "$OUT"

echo "▶ 11. Ochrona sieci: blocklist (count/strip na atrapie /etc/hosts)"
# shellcheck source=/dev/null
source "$LIB/protect.sh"
assert_true "protect_count zdefiniowane" declare -F protect_count
assert_true "run_protect zdefiniowane"   declare -F run_protect
FAKE="$(mktemp)"
{ echo "127.0.0.1 localhost"; echo "$PROTECT_START"; echo "0.0.0.0 evil.test"; echo "0.0.0.0 bad.test"; echo "$PROTECT_END"; echo "10.0.0.5 dev"; } > "$FAKE"
HOSTS="$FAKE"
assert_eq "protect_count liczy blok" "2" "$(protect_count)"
STRIPPED="$(_protect_strip)"
assert_contains "strip zachowuje localhost" "localhost" "$STRIPPED"
assert_contains "strip zachowuje dev"       "dev"       "$STRIPPED"
assert_absent   "strip usuwa evil.test"     "evil.test" "$STRIPPED"
assert_true "seed blocklisty istnieje" test -f "$LIB/blocklist-seed.txt"
rm -f "$FAKE"; HOSTS="/etc/hosts"

echo "▶ 12. Bezpieczeństwo: silnik jest read-only (brak groźnych wzorców)"
# Groźne: rm -rf ze zmienną, pobieranie|powłoka z URL. (Opisy 'curl|bash' w tekstach są OK.)
if grep -REn 'rm +-rf +\$|(curl|wget)[^|]*https?://[^|]*\|[[:space:]]*(ba)?sh' "$LIB" "$ROOT/secure-scan.sh" 2>/dev/null; then
  bad "znaleziono groźny wzorzec w kodzie silnika"
else
  ok "brak groźnych wzorców (rm -rf \$var, pobieranie|powłoka)"
fi

echo ""
echo "════════════════════════════════════════"
printf "  TESTY: %s ✅   %s ❌\n" "$PASS" "$FAIL"
echo "════════════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then printf "Nieudane:%b\n" "$FAILED"; exit 1; fi
echo "✅ Wszystkie testy przeszły."
