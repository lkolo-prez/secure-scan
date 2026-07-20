#!/bin/bash
# ============================================================================
#  secure-scan — Security Score Dashboard dla macOS (Apple Silicon & Intel)
#  https://github.com/lkolo-prez/secure-scan
#
#  20 kontroli bezpieczeństwa w 5 kategoriach -> wynik 0-100 + dashboard HTML.
#  Wszystkie kontrole są READ-ONLY. Nie modyfikują systemu. Nie wymagają sudo.
#
#  Użycie:
#    ./secure-scan.sh              skan + dashboard HTML (otwiera w przeglądarce)
#    ./secure-scan.sh --no-open    nie otwieraj przeglądarki
#    ./secure-scan.sh --json       wypisz wynik jako JSON (do automatyzacji/CI)
#    ./secure-scan.sh --help       pomoc
#    ./secure-scan.sh --version    wersja
# ============================================================================
set -uo pipefail

VERSION="1.0.0"
OUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HTML="$OUT_DIR/security-dashboard.html"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

MODE="html"
OPEN=1
for arg in "$@"; do
  case "$arg" in
    --no-open) OPEN=0 ;;
    --json)    MODE="json"; OPEN=0 ;;
    --help|-h)
      grep '^#' "$0" | grep -vE '^#!' | sed 's/^# \{0,1\}//' | head -20
      exit 0 ;;
    --version|-v) echo "secure-scan $VERSION"; exit 0 ;;
    *) echo "Nieznany argument: $arg (użyj --help)"; exit 1 ;;
  esac
done

# --- Stan globalny ----------------------------------------------------------
EARNED=0; POSSIBLE=0
N_PASS=0; N_WARN=0; N_FAIL=0
SECTIONS=""; JSON="["
# --- Stan bieżącej kategorii ------------------------------------------------
CAT_CARDS=""; CAT_EARNED=0; CAT_POSSIBLE=0; CAT_NAME=""; CAT_ICON=""

begin_cat() { CAT_NAME="$1"; CAT_ICON="$2"; CAT_CARDS=""; CAT_EARNED=0; CAT_POSSIBLE=0; }

end_cat() {
  local pct=$(( CAT_POSSIBLE>0 ? CAT_EARNED*100/CAT_POSSIBLE : 100 ))
  local col="#22c55e"; [ "$pct" -lt 90 ] && col="#84cc16"; [ "$pct" -lt 75 ] && col="#f59e0b"; [ "$pct" -lt 60 ] && col="#ef4444"
  SECTIONS="$SECTIONS
  <section>
    <div class='cat-head'>
      <h2>$CAT_ICON &nbsp;$CAT_NAME</h2>
      <div class='cat-score'><div class='cat-bar'><i style='width:${pct}%;background:$col'></i></div><b style='color:$col'>${pct}%</b></div>
    </div>
    <div class='grid'>$CAT_CARDS</div>
  </section>"
}

# add_check "Nazwa" STATUS WAGA "Szczegóły" "Komenda naprawcza (lub pusto)"
add_check() {
  local name="$1" status="$2" weight="$3" detail="$4" fix="$5"
  local pts=$(( weight*2 )) got=0 color icon label
  POSSIBLE=$(( POSSIBLE+pts )); CAT_POSSIBLE=$(( CAT_POSSIBLE+pts ))
  case "$status" in
    PASS) got=$pts;    color="#22c55e"; icon="&#10003;"; label="OK";    N_PASS=$((N_PASS+1)) ;;
    WARN) got=$weight; color="#f59e0b"; icon="&#9888;";  label="UWAGA"; N_WARN=$((N_WARN+1)) ;;
    FAIL) got=0;       color="#ef4444"; icon="&#10007;"; label="BŁĄD";  N_FAIL=$((N_FAIL+1)) ;;
  esac
  EARNED=$(( EARNED+got )); CAT_EARNED=$(( CAT_EARNED+got ))
  local fixhtml=""
  [ -n "$fix" ] && fixhtml="<div class='fix'><span>Napraw:</span> <code>$fix</code></div>"
  CAT_CARDS="$CAT_CARDS
  <div class='card' style='border-left-color:$color'>
    <div class='card-head'><span class='badge' style='background:$color'>$icon $label</span><span class='wt'>waga $weight</span></div>
    <div class='card-name'>$name</div>
    <div class='detail'>$detail</div>$fixhtml
  </div>"
  local jdetail="${detail//\"/\'}"
  JSON="$JSON{\"category\":\"$CAT_NAME\",\"name\":\"$name\",\"status\":\"$status\",\"weight\":$weight,\"detail\":\"$jdetail\"},"
}

[ "$MODE" = "html" ] && echo "==> Skanuję system (20 kontroli, read-only)…"

# ============================================================================
#  A. SZYFROWANIE I ROZRUCH
# ============================================================================
begin_cat "Szyfrowanie i rozruch" "&#128274;"

fdesetup status 2>/dev/null | grep -q "FileVault is On" \
  && add_check "Szyfrowanie dysku (FileVault)" PASS 10 "Dysk zaszyfrowany — dane bezpieczne przy kradzieży." "" \
  || add_check "Szyfrowanie dysku (FileVault)" FAIL 10 "FileVault WYŁĄCZONY — dane odczytywalne po wyjęciu dysku." "sudo fdesetup enable"

csrutil status 2>/dev/null | grep -qi "enabled" \
  && add_check "System Integrity Protection (SIP)" PASS 10 "Ochrona plików systemowych aktywna." "" \
  || add_check "System Integrity Protection (SIP)" FAIL 10 "SIP WYŁĄCZONY — malware może modyfikować system." "W trybie recovery: csrutil enable"

SB="$(system_profiler SPiBridgeDataType 2>/dev/null)"
if echo "$SB" | grep -qiE "Full Security|Pełna ochrona"; then
  add_check "Secure Boot" PASS 7 "Pełna ochrona rozruchu + Signed System Volume." ""
elif echo "$SB" | grep -qi "Secure Boot"; then
  add_check "Secure Boot" WARN 7 "Secure Boot nie w trybie pełnym." "Ustaw 'Full Security' w Startup Security Utility"
else
  add_check "Secure Boot" PASS 7 "Rozruch chroniony (Signed System Volume aktywne)." ""
fi
end_cat

# ============================================================================
#  B. SIEĆ I ZAPORA
# ============================================================================
begin_cat "Sieć i zapora" "&#127760;"

/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -qi "enabled" \
  && add_check "Zapora sieciowa (przychodząca)" PASS 10 "Firewall aplikacyjny włączony." "" \
  || add_check "Zapora sieciowa (przychodząca)" FAIL 10 "Firewall WYŁĄCZONY — Mac odpowiada na połączenia z sieci." "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"

/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -qi "on" \
  && add_check "Tryb ukrycia (stealth)" PASS 5 "Mac nie odpowiada na ping/skanowanie portów." "" \
  || add_check "Tryb ukrycia (stealth)" WARN 5 "Stealth wyłączony — Mac widoczny na skanowanie." "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on"

lsof -nP -iTCP:22 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "Zdalne logowanie (SSH)" WARN 5 "Port 22 nasłuchuje — SSH włączone." "sudo systemsetup -setremotelogin off" \
  || add_check "Zdalne logowanie (SSH)" PASS 5 "SSH wyłączone (port 22 zamknięty)." ""

lsof -nP -iTCP:5900 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "Współdzielenie ekranu (VNC)" WARN 5 "Port 5900 nasłuchuje — Screen Sharing aktywne." "Ustawienia > Ogólne > Udostępnianie > wyłącz" \
  || add_check "Współdzielenie ekranu (VNC)" PASS 5 "Screen Sharing wyłączone." ""

lsof -nP -iTCP:7000 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "Odbiornik AirPlay" WARN 3 "Porty 5000/7000 otwarte (AirPlay Receiver)." "Ustawienia > Ogólne > AirDrop i Handoff > Odbiornik AirPlay: Wył." \
  || add_check "Odbiornik AirPlay" PASS 3 "Odbiornik AirPlay wyłączony." ""
end_cat

# ============================================================================
#  C. AKTUALIZACJE I OCHRONA
# ============================================================================
begin_cat "Aktualizacje i ochrona" "&#128737;"

[ "$MODE" = "html" ] && echo "   …sprawdzam aktualizacje (może chwilę potrwać)…"
if softwareupdate --list 2>&1 | grep -qi "No new software"; then
  add_check "Aktualizacje systemu" PASS 10 "Brak zaległych aktualizacji — system aktualny." ""
else
  add_check "Aktualizacje systemu" WARN 10 "Dostępne aktualizacje do zainstalowania." "sudo softwareupdate -ia --restart"
fi

AU="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates 2>/dev/null)"
CD="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall 2>/dev/null)"
if [ "$AU" = "1" ] && [ "$CD" = "1" ]; then
  add_check "Automatyczne aktualizacje" PASS 7 "Auto-instalacja aktualizacji i danych bezpieczeństwa włączona." ""
else
  add_check "Automatyczne aktualizacje" WARN 7 "Część automatycznych aktualizacji wyłączona." "Ustawienia > Ogólne > Aktualizacja"
fi

spctl --status 2>/dev/null | grep -qi "assessments enabled" \
  && add_check "Gatekeeper" PASS 7 "Blokuje niepodpisane/nieznane aplikacje." "" \
  || add_check "Gatekeeper" FAIL 7 "Gatekeeper wyłączony — można uruchomić dowolną aplikację." "sudo spctl --master-enable"

XP="$(defaults read /System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)"
[ -n "$XP" ] \
  && add_check "XProtect (antywirus Apple)" PASS 5 "Wbudowany silnik anty-malware aktywny (wersja $XP)." "" \
  || add_check "XProtect (antywirus Apple)" WARN 5 "Nie odczytano wersji XProtect." ""
end_cat

# ============================================================================
#  D. KONTA I DOSTĘP
# ============================================================================
begin_cat "Konta i dostęp" "&#128100;"

dscl . -read /Users/root Password 2>/dev/null | grep -q '\*' \
  && add_check "Konto root" PASS 5 "Konto root wyłączone." "" \
  || add_check "Konto root" WARN 5 "Konto root może być włączone." "dsenableroot -d"

sysadminctl -guestAccount status 2>&1 | grep -qi "disabled" \
  && add_check "Konto gościa" PASS 5 "Konto gościa wyłączone." "" \
  || add_check "Konto gościa" WARN 5 "Konto gościa włączone." "sysadminctl -guestAccount off"

AL="$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null)"
[ -z "$AL" ] \
  && add_check "Automatyczne logowanie" PASS 7 "Auto-login wyłączony — wymagane hasło przy starcie." "" \
  || add_check "Automatyczne logowanie" FAIL 7 "Auto-login WŁĄCZONY dla '$AL' — każdy uruchamia system bez hasła." "Ustawienia > Użytkownicy > Opcje logowania"

SL="$(sysadminctl -screenLock status 2>&1)"
if echo "$SL" | grep -qi "off"; then
  add_check "Blokada ekranu hasłem" FAIL 7 "Ekran nie wymaga hasła po wygaszeniu." "Ustawienia > Ekran blokady > Wymagaj hasła"
elif echo "$SL" | grep -qiE "delay is 0 |immediat"; then
  add_check "Blokada ekranu hasłem" PASS 7 "Hasło wymagane natychmiast po wygaszeniu." ""
else
  DLY="$(echo "$SL" | grep -oE '[0-9]+ seconds' | head -1)"
  add_check "Blokada ekranu hasłem" WARN 7 "Hasło wymagane, ale z opóźnieniem (${DLY:-?}). Zalecane: natychmiast." "sysadminctl -screenLock immediate"
fi
end_cat

# ============================================================================
#  E. PRYWATNOŚĆ I MALWARE
# ============================================================================
begin_cat "Prywatność i malware" "&#128269;"

KEXT="$(kmutil showloaded --list-only 2>/dev/null | grep -cv 'com.apple')"; KEXT="${KEXT//[^0-9]/}"; KEXT="${KEXT:-0}"
[ "$KEXT" -eq 0 ] \
  && add_check "Rozszerzenia jądra (kext)" PASS 7 "Brak rozszerzeń jądra firm trzecich — brak śladów rootkitów." "" \
  || add_check "Rozszerzenia jądra (kext)" WARN 7 "Wykryto $KEXT rozszerzeń spoza Apple — zweryfikuj źródło." "kmutil showloaded --list-only | grep -v com.apple"

SEXT="$(systemextensionsctl list 2>/dev/null | grep -oE '^[0-9]+ extension' | grep -oE '^[0-9]+')"; SEXT="${SEXT:-0}"
[ "$SEXT" -eq 0 ] \
  && add_check "Rozszerzenia systemowe" PASS 5 "Brak rozszerzeń sieciowych/endpoint firm trzecich." "" \
  || add_check "Rozszerzenia systemowe" WARN 5 "Aktywne $SEXT rozszerzeń systemowych — zweryfikuj." "systemextensionsctl list"

ADW=""
for d in "/Library/Application Support" "$HOME/Library/Application Support"; do
  ADW="$ADW$(find "$d" -maxdepth 1 -iregex '.*\(genieo\|vsearch\|mackeeper\|advanced mac\|mac cleanup\|spigot\|conduit\|installmac\|pcvark\|amc\).*' 2>/dev/null)"
done
[ -z "$ADW" ] \
  && add_check "Znany adware / PUP" PASS 7 "Nie wykryto znanego adware (Genieo, MacKeeper, itp.)." "" \
  || add_check "Znany adware / PUP" FAIL 7 "Wykryto podejrzane pliki adware — do usunięcia." "Usuń wykryte katalogi i uruchom Malwarebytes"

if profiles list 2>/dev/null | grep -qi "no configuration profiles"; then
  add_check "Profile konfiguracyjne / MDM" PASS 3 "Brak zewnętrznych profili konfiguracyjnych." ""
else
  add_check "Profile konfiguracyjne / MDM" WARN 3 "Zainstalowane profile konfiguracyjne — zweryfikuj pochodzenie." "profiles list"
fi
end_cat

# ============================================================================
#  WYNIK KOŃCOWY
# ============================================================================
SCORE=$(( POSSIBLE>0 ? EARNED*100/POSSIBLE : 0 ))
if   [ "$SCORE" -ge 90 ]; then GRADE="Bardzo dobry"; GCOL="#22c55e"
elif [ "$SCORE" -ge 75 ]; then GRADE="Dobry";        GCOL="#84cc16"
elif [ "$SCORE" -ge 60 ]; then GRADE="Do poprawy";   GCOL="#f59e0b"
else                           GRADE="Słaby";        GCOL="#ef4444"; fi

MODEL="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip|Processor Name/{print $2; exit}')"
OSV="$(sw_vers -productVersion 2>/dev/null)"
TOTAL=$(( N_PASS+N_WARN+N_FAIL ))

# --- Tryb JSON --------------------------------------------------------------
if [ "$MODE" = "json" ]; then
  JSON="${JSON%,}]"
  printf '{"version":"%s","scanned_at":"%s","model":"%s","os":"%s","score":%s,"grade":"%s","pass":%s,"warn":%s,"fail":%s,"checks":%s}\n' \
    "$VERSION" "$NOW" "$MODEL" "$OSV" "$SCORE" "$GRADE" "$N_PASS" "$N_WARN" "$N_FAIL" "$JSON"
  exit 0
fi

# --- Generowanie HTML -------------------------------------------------------
cat > "$HTML" <<HTMLEOF
<!doctype html><html lang="pl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Security Score — macOS</title>
<style>
  :root{--bg:#0b0f17;--card:#151b26;--txt:#e6edf3;--mut:#8b96a5;--line:#232c3a}
  @media (prefers-color-scheme:light){:root{--bg:#f4f6fa;--card:#fff;--txt:#0b0f17;--mut:#5b6675;--line:#e2e7ee}}
  *{box-sizing:border-box;margin:0;padding:0}
  body{background:var(--bg);color:var(--txt);font:15px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;padding:32px 20px;max-width:1120px;margin:0 auto}
  header{text-align:center;margin-bottom:8px}
  h1{font-size:23px;font-weight:800;letter-spacing:-.3px}
  .sub{color:var(--mut);font-size:13px;margin-top:4px}
  .hero{display:flex;gap:34px;align-items:center;justify-content:center;flex-wrap:wrap;margin:28px 0 34px}
  .gauge{width:210px;height:210px;border-radius:50%;display:grid;place-items:center;background:conic-gradient($GCOL ${SCORE}%,var(--line) 0);position:relative;flex:none}
  .gauge::before{content:"";position:absolute;inset:14px;border-radius:50%;background:var(--bg)}
  .gval{position:relative;text-align:center}
  .gnum{font-size:58px;font-weight:800;line-height:1;color:$GCOL}
  .gnum span{font-size:22px;color:var(--mut)}
  .gpct{font-size:12px;color:var(--mut);margin-top:6px;letter-spacing:1.5px;text-transform:uppercase}
  .stats{display:flex;gap:14px;flex-wrap:wrap;justify-content:center}
  .stat{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px 22px;min-width:104px;text-align:center}
  .stat b{font-size:28px;display:block}
  .stat.ok b{color:#22c55e}.stat.warn b{color:#f59e0b}.stat.fail b{color:#ef4444}
  .stat small{color:var(--mut);font-size:12px}
  .grade{display:inline-block;padding:5px 16px;border-radius:20px;font-weight:700;font-size:13px;color:#0b0f17;background:$GCOL;margin-top:12px}
  section{margin-top:26px}
  .cat-head{display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid var(--line);padding-bottom:8px;margin-bottom:14px}
  h2{font-size:15px;font-weight:700}
  .cat-score{display:flex;align-items:center;gap:10px}
  .cat-bar{width:120px;height:7px;background:var(--line);border-radius:4px;overflow:hidden}
  .cat-bar i{display:block;height:100%}
  .cat-score b{font-size:13px;min-width:38px;text-align:right}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:13px}
  .card{background:var(--card);border:1px solid var(--line);border-left:4px solid;border-radius:12px;padding:15px}
  .card-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
  .badge{color:#0b0f17;font-weight:700;font-size:11px;padding:3px 10px;border-radius:6px}
  .wt{color:var(--mut);font-size:11px}
  .card-name{font-weight:600;font-size:15px;margin-bottom:6px}
  .detail{color:var(--mut);font-size:13px}
  .fix{margin-top:10px;font-size:12px}
  .fix span{color:#f59e0b;font-weight:600}
  .fix code{background:rgba(125,211,252,.08);border:1px solid var(--line);border-radius:5px;padding:2px 6px;color:#38bdf8;font-size:11px;word-break:break-all}
  footer{text-align:center;color:var(--mut);font-size:12px;margin-top:34px;line-height:1.8}
  footer code{color:#38bdf8}
  footer a{color:#38bdf8;text-decoration:none}
</style></head><body>
<header>
  <h1>&#128737;&#65039; Security Score Dashboard</h1>
  <div class="sub">$MODEL &middot; macOS $OSV &middot; skan: $NOW</div>
</header>
<div class="hero">
  <div class="gauge"><div class="gval"><div class="gnum">$SCORE<span>/100</span></div><div class="gpct">Security Score</div></div></div>
  <div>
    <div class="stats">
      <div class="stat ok"><b>$N_PASS</b><small>OK</small></div>
      <div class="stat warn"><b>$N_WARN</b><small>Uwaga</small></div>
      <div class="stat fail"><b>$N_FAIL</b><small>Błąd</small></div>
    </div>
    <div style="text-align:center"><span class="grade">$GRADE</span></div>
  </div>
</div>
$SECTIONS
<footer>
  <b>secure-scan v$VERSION</b> &middot; $TOTAL kontroli, wszystkie read-only<br>
  Odśwież wynik: <code>./secure-scan.sh</code> &middot;
  <a href="https://github.com/lkolo-prez/secure-scan">github.com/lkolo-prez/secure-scan</a>
</footer>
</body></html>
HTMLEOF

echo ""
echo "  ================================================"
printf "   SECURITY SCORE: %s/100  (%s)\n" "$SCORE" "$GRADE"
printf "   OK: %s   Uwaga: %s   Błąd: %s   (z %s kontroli)\n" "$N_PASS" "$N_WARN" "$N_FAIL" "$TOTAL"
echo "  ================================================"
echo "   Dashboard: $HTML"
[ "$OPEN" = "1" ] && open "$HTML" 2>/dev/null && echo "   (otwieram w przeglądarce…)"
exit 0
