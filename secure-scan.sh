#!/bin/bash
# ============================================================================
#  secure-scan — Advanced macOS Security Score Dashboard
#  by Aircloud — Łukasz Kołodziej
#  https://github.com/lkolo-prez/secure-scan   |   MIT   |   PL / EN
#
#  Kontrole READ-ONLY (skan niczego nie zmienia). --fix wykonuje naprawy za
#  zgodą użytkownika. Bez zależności zewnętrznych.
#
#  Użycie / Usage:
#    secure-scan                 skan + dashboard HTML / scan + HTML dashboard
#    secure-scan --fix           auto-naprawa (pyta o zgodę) / auto-fix (asks)
#    secure-scan --fix --yes     napraw wszystko bez pytań / fix all, no prompts
#    secure-scan --protect       włącz blokadę groźnych domen / enable domain blocking
#    secure-scan --unprotect     wyłącz blokadę domen / disable domain blocking
#    secure-scan --json          wynik JSON (CI) / JSON output (CI)
#    secure-scan --lang en|pl    język / language
#    secure-scan --only core,malware,perf   wybrane moduły / selected modules
#    secure-scan --no-open       nie otwieraj przeglądarki / don't open browser
#    secure-scan --help          pomoc / help
#    secure-scan --version       wersja / version
#
#  Moduły / Modules: core, malware, browser, perf, network, files, downloads
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SCRIPT_DIR/lib"
# OUT_DIR nadpisywalny (np. gdy silnik działa z wnętrza .app — bundle jest tylko do odczytu)
OUT_DIR="${SECURE_SCAN_OUT:-$SCRIPT_DIR}"
HTML="$OUT_DIR/security-dashboard.html"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# --- Auto-wykrycie języka ---------------------------------------------------
LANG_SEL="pl"
_loc="$(defaults read -g AppleLocale 2>/dev/null || echo "${LANG:-}")"
case "$_loc" in en*|EN*) LANG_SEL="en" ;; esac

# --- Parsowanie argumentów --------------------------------------------------
MODE="html"; OPEN=1; DO_FIX=0; AUTO_YES=0; NOTIFY=1; DO_PROTECT=""
MODULES="core malware browser perf network files downloads"

while [ $# -gt 0 ]; do
  case "$1" in
    --fix)      DO_FIX=1 ;;
    --protect)        DO_PROTECT="on" ;;
    --unprotect)      DO_PROTECT="off" ;;
    --protect-status) DO_PROTECT="status" ;;
    --yes|-y)   AUTO_YES=1 ;;
    --json)     MODE="json"; OPEN=0; NOTIFY=0 ;;
    --no-open)  OPEN=0 ;;
    --no-notify) NOTIFY=0 ;;
    --lang)     shift; LANG_SEL="${1:-pl}" ;;
    --lang=*)   LANG_SEL="${1#*=}" ;;
    --only)     shift; MODULES="$(echo "${1:-}" | tr ',' ' ')" ;;
    --only=*)   MODULES="$(echo "${1#*=}" | tr ',' ' ')" ;;
    --help|-h)  grep '^#' "$0" | grep -vE '^#!' | sed 's/^# \{0,1\}//' | sed -n '1,24p'; exit 0 ;;
    --version|-v) source "$LIB/core.sh"; echo "secure-scan $VERSION"; exit 0 ;;
    *) echo "Nieznany argument / Unknown arg: $1 (--help)"; exit 1 ;;
  esac
  shift
done
export AUTO_YES

# --- Ładowanie bibliotek ----------------------------------------------------
source "$LIB/core.sh"
source "$LIB/checks_core.sh"
source "$LIB/checks_malware.sh"
source "$LIB/checks_browser.sh"
source "$LIB/checks_perf.sh"
source "$LIB/checks_network.sh"
source "$LIB/checks_files.sh"
source "$LIB/checks_downloads.sh"
source "$LIB/remediate.sh"
source "$LIB/protect.sh"

# --- Ochrona sieci (blocklist) ----------------------------------------------
if [ -n "$DO_PROTECT" ]; then
  case "$DO_PROTECT" in
    on)     run_protect ;;
    off)    run_unprotect ;;
    status) protect_count ;;
  esac
  exit $?
fi

# --- Tryb naprawy -----------------------------------------------------------
if [ "$DO_FIX" = "1" ]; then
  run_fix
  echo ""
  echo "$(L '→ Uruchamiam ponowny skan…' '→ Running a fresh scan…')"
  echo ""
fi

# --- Skan -------------------------------------------------------------------
[ "$MODE" = "html" ] && echo "==> $(L 'Skanuję system' 'Scanning system') ($(echo $MODULES | wc -w | tr -d ' ') $(L 'modułów, read-only' 'modules, read-only'))…"

for m in $MODULES; do
  case "$m" in
    core)    [ "$MODE" = "html" ] && echo "── $(L 'System' 'System') ──";       run_core ;;
    malware) [ "$MODE" = "html" ] && echo "── Malware ──";                       run_malware ;;
    browser) [ "$MODE" = "html" ] && echo "── $(L 'Przeglądarki' 'Browsers') ──"; run_browser ;;
    perf)    [ "$MODE" = "html" ] && echo "── $(L 'Wydajność' 'Performance') ──"; run_perf ;;
    network) [ "$MODE" = "html" ] && echo "── $(L 'Sieć' 'Network') ──";          run_network ;;
    files)   [ "$MODE" = "html" ] && echo "── $(L 'Pliki' 'Files') ──";           run_files ;;
    downloads) [ "$MODE" = "html" ] && echo "── $(L 'Pobrane' 'Downloads') ──";   run_downloads ;;
  esac
done

finalize_score

if [ "$MODE" = "json" ]; then
  render_json
  exit 0
fi

build_nav
render_html

echo ""
echo "  ════════════════════════════════════════════════"
printf "   SECURITY SCORE: %s/100  (%s)\n" "$SCORE" "$GRADE"
printf "   OK: %s   %s: %s   %s: %s   Info: %s\n" "$N_PASS" "$(L Uwaga Warn)" "$N_WARN" "$(L Błąd Fail)" "$N_FAIL" "$N_INFO"
echo "  ════════════════════════════════════════════════"
echo "   Dashboard: $HTML"
[ "$N_FAIL" -gt 0 ] && echo "   $(L '→ Napraw błędy:' '→ Fix issues:') secure-scan --fix"

[ "$NOTIFY" = "1" ] && notify "secure-scan — Score $SCORE/100" "$GRADE · $N_PASS OK, $N_WARN $(L uwag warn), $N_FAIL $(L błędów fail)"
[ "$OPEN" = "1" ] && open "$HTML" 2>/dev/null && echo "   ($(L 'otwieram w przeglądarce' 'opening in browser')…)"
exit 0
