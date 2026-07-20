#!/bin/bash
# lib/remediate.sh — auto-naprawa (--fix). Sourced by secure-scan.sh.
# Każdy krok: jeśli już bezpiecznie -> pomiń; inaczej zapytaj (chyba że --yes) i napraw.

AUTO_YES="${AUTO_YES:-0}"
FIX_DONE=0; FIX_SKIP=0

# fix_step "opis" "test_bezpieczny (exit 0 = już OK)" "komenda naprawcza"
fix_step() {
  local desc="$1" test_cmd="$2" fix_cmd="$3"
  if eval "$test_cmd" >/dev/null 2>&1; then
    printf "   ✅ %s — %s\n" "$desc" "$(L 'już bezpieczne' 'already secure')"
    return
  fi
  printf "   ⚠️  %s — %s\n" "$desc" "$(L 'wymaga naprawy' 'needs fixing')"
  printf "      → %s\n" "$fix_cmd"
  local ans="y"
  if [ "$AUTO_YES" != "1" ]; then
    printf "      %s [y/N]: " "$(L 'Zastosować?' 'Apply?')"
    read -r ans </dev/tty || ans="n"
  fi
  case "$ans" in
    y|Y|t|T)
      if eval "sudo $fix_cmd" >/dev/null 2>&1; then
        printf "      ✅ %s\n" "$(L 'naprawiono' 'fixed')"; FIX_DONE=$((FIX_DONE+1))
      else
        printf "      ❌ %s\n" "$(L 'nie udało się (uruchom komendę ręcznie)' 'failed (run the command manually)')"
      fi ;;
    *) printf "      ⏭️  %s\n" "$(L 'pominięto' 'skipped')"; FIX_SKIP=$((FIX_SKIP+1)) ;;
  esac
}

run_fix() {
  echo ""
  echo "🔧 $(L 'AUTO-NAPRAWA — utwardzanie systemu' 'AUTO-FIX — system hardening')"
  echo "   $(L 'Wymaga hasła administratora (sudo). Zmiany są odwracalne.' 'Requires admin password (sudo). Changes are reversible.')"
  echo ""
  if ! sudo -v 2>/dev/null; then
    echo "   ❌ $(L 'Brak uprawnień sudo — przerwano.' 'No sudo access — aborted.')"
    return 1
  fi

  local FW=/usr/libexec/ApplicationFirewall/socketfilterfw
  fix_step "$(L 'Zapora sieciowa' 'Firewall')" \
    "$FW --getglobalstate | grep -qi enabled" \
    "$FW --setglobalstate on"
  fix_step "$(L 'Tryb ukrycia (stealth)' 'Stealth mode')" \
    "$FW --getstealthmode | grep -qi on" \
    "$FW --setstealthmode on"
  fix_step "Gatekeeper" \
    "spctl --status | grep -qi 'assessments enabled'" \
    "spctl --global-enable"
  fix_step "$(L 'Konto gościa' 'Guest account')" \
    "sysadminctl -guestAccount status 2>&1 | grep -qi disabled" \
    "sysadminctl -guestAccount off"
  fix_step "$(L 'Blokada ekranu natychmiast' 'Immediate screen lock')" \
    "sysadminctl -screenLock status 2>&1 | grep -qiE 'delay is 0 |immediat'" \
    "sysadminctl -screenLock immediate"
  fix_step "$(L 'Wyłącz zdalne logowanie (SSH)' 'Disable Remote Login (SSH)')" \
    "! lsof -nP -iTCP:22 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN" \
    "systemsetup -setremotelogin off"

  echo ""
  echo "   $(L 'Naprawiono:' 'Fixed:') $FIX_DONE   $(L 'Pominięto:' 'Skipped:') $FIX_SKIP"
  echo "   $(L 'Uruchom ponownie skan, aby zobaczyć nowy wynik:' 'Re-run the scan to see the new score:') secure-scan"
  notify "secure-scan" "$(L 'Naprawiono' 'Fixed') $FIX_DONE $(L 'ustawień bezpieczeństwa' 'security settings')"
}
