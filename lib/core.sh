#!/bin/bash
# ============================================================================
#  lib/core.sh — framework: i18n, scoring, karty, render HTML/JSON, notyfikacje
#  Sourced by secure-scan.sh. Nie uruchamiaj bezpośrednio.
# ============================================================================

VERSION="3.2.0"

# --- i18n: L "polski" "english" ---------------------------------------------
# LANG_SEL ustawiane w secure-scan.sh (pl|en)
L() { if [ "${LANG_SEL:-pl}" = "en" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# --- Stan globalny ----------------------------------------------------------
EARNED=0; POSSIBLE=0
N_PASS=0; N_WARN=0; N_FAIL=0; N_INFO=0
SECTIONS=""; JSON="["; CAT_NAMES=""
CAT_CARDS=""; CAT_EARNED=0; CAT_POSSIBLE=0; CAT_NAME=""; CAT_ICON=""

begin_cat() { CAT_NAME="$1"; CAT_ICON="$2"; CAT_CARDS=""; CAT_EARNED=0; CAT_POSSIBLE=0; }

end_cat() {
  local pct=100
  [ "$CAT_POSSIBLE" -gt 0 ] && pct=$(( CAT_EARNED*100/CAT_POSSIBLE ))
  local col="#22c55e"; [ "$pct" -lt 90 ] && col="#84cc16"; [ "$pct" -lt 75 ] && col="#f59e0b"; [ "$pct" -lt 60 ] && col="#ef4444"
  local anchor; anchor="$(echo "$CAT_NAME" | tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9-')"
  CAT_NAMES="${CAT_NAMES}${CAT_NAME}
"
  SECTIONS="$SECTIONS
  <section id='$anchor'>
    <div class='cat-head'>
      <h2>$CAT_ICON &nbsp;$CAT_NAME</h2>
      <div class='cat-score'><div class='cat-bar'><i style='width:${pct}%;background:$col'></i></div><b style='color:$col'>${pct}%</b></div>
    </div>
    <div class='grid'>$CAT_CARDS</div>
  </section>"
}

# add_check "Nazwa" STATUS WAGA "Szczegóły" "Komenda naprawcza|"
#   STATUS: PASS | WARN | FAIL | INFO  (INFO nie wpływa na wynik)
add_check() {
  local name="$1" status="$2" weight="$3" detail="$4" fix="$5"
  local pts=$(( weight*2 )) got=0 color icon label
  case "$status" in
    PASS) got=$pts;    color="#22c55e"; icon="&#10003;"; label="$(L OK OK)";       N_PASS=$((N_PASS+1)); POSSIBLE=$((POSSIBLE+pts)); CAT_POSSIBLE=$((CAT_POSSIBLE+pts)) ;;
    WARN) got=$weight; color="#f59e0b"; icon="&#9888;";  label="$(L UWAGA WARN)";  N_WARN=$((N_WARN+1)); POSSIBLE=$((POSSIBLE+pts)); CAT_POSSIBLE=$((CAT_POSSIBLE+pts)) ;;
    FAIL) got=0;       color="#ef4444"; icon="&#10007;"; label="$(L BŁĄD FAIL)";   N_FAIL=$((N_FAIL+1)); POSSIBLE=$((POSSIBLE+pts)); CAT_POSSIBLE=$((CAT_POSSIBLE+pts)) ;;
    INFO) got=0;       color="#38bdf8"; icon="&#8505;";  label="$(L INFO INFO)";   N_INFO=$((N_INFO+1)) ;;
  esac
  EARNED=$(( EARNED+got )); CAT_EARNED=$(( CAT_EARNED+got ))
  local fixhtml=""
  [ -n "$fix" ] && fixhtml="<div class='fix'><span>$(L Napraw Fix):</span> <code>$fix</code></div>"
  CAT_CARDS="$CAT_CARDS
  <div class='card' style='border-left-color:$color'>
    <div class='card-head'><span class='badge' style='background:$color'>$icon $label</span><span class='wt'>$(L waga weight) $weight</span></div>
    <div class='card-name'>$name</div>
    <div class='detail'>$detail</div>$fixhtml
  </div>"
  # Poprawne escapowanie JSON (odporne na backslashe z danych, np. lsof \x20)
  local jn jd jc
  jn="${name//\\/\\\\}";     jn="${jn//$'\n'/\\n}"; jn="${jn//\\\\n/\\n}"; jn="${jn//\"/\\\"}"
  jd="${detail//\\/\\\\}";   jd="${jd//$'\n'/\\n}"; jd="${jd//\\\\n/\\n}"; jd="${jd//\"/\\\"}"
  jc="${CAT_NAME//\\/\\\\}"; jc="${jc//\"/\\\"}"
  JSON="$JSON{\"category\":\"$jc\",\"name\":\"$jn\",\"status\":\"$status\",\"weight\":$weight,\"detail\":\"$jd\"},"
  # Wyjście na żywo w terminalu
  if [ "${MODE:-html}" = "html" ]; then
    local sym; case "$status" in PASS) sym="✅";; WARN) sym="⚠️ ";; FAIL) sym="❌";; INFO) sym="ℹ️ ";; esac
    printf "   %s %s\n" "$sym" "$name"
  fi
}

# --- Natywna notyfikacja macOS ----------------------------------------------
notify() {
  local title="$1" msg="$2"
  osascript -e "display notification \"$msg\" with title \"$title\"" >/dev/null 2>&1 || true
}

# --- Render finalny (score + HTML) ------------------------------------------
finalize_score() {
  SCORE=0
  [ "$POSSIBLE" -gt 0 ] && SCORE=$(( EARNED*100/POSSIBLE ))
  if   [ "$SCORE" -ge 90 ]; then GRADE="$(L 'Bardzo dobry' 'Excellent')"; GCOL="#22c55e"
  elif [ "$SCORE" -ge 75 ]; then GRADE="$(L 'Dobry' 'Good')";             GCOL="#84cc16"
  elif [ "$SCORE" -ge 60 ]; then GRADE="$(L 'Do poprawy' 'Needs work')";  GCOL="#f59e0b"
  else                           GRADE="$(L 'Słaby' 'Poor')";             GCOL="#ef4444"; fi
  TOTAL=$(( N_PASS+N_WARN+N_FAIL ))
}

render_json() {
  JSON="${JSON%,}]"
  local model os
  model="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip|Processor Name/{print $2; exit}')"
  os="$(sw_vers -productVersion 2>/dev/null)"
  printf '{"tool":"secure-scan","version":"%s","scanned_at":"%s","lang":"%s","model":"%s","os":"%s","score":%s,"grade":"%s","pass":%s,"warn":%s,"fail":%s,"info":%s,"checks":%s}\n' \
    "$VERSION" "$NOW" "${LANG_SEL:-pl}" "$model" "$os" "$SCORE" "$GRADE" "$N_PASS" "$N_WARN" "$N_FAIL" "$N_INFO" "$JSON"
}

render_html() {
  local model os
  model="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Chip|Processor Name/{print $2; exit}')"
  os="$(sw_vers -productVersion 2>/dev/null)"
  cat > "$HTML" <<HTMLEOF
<!doctype html><html lang="${LANG_SEL:-pl}"><head><meta charset="utf-8">
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
  .hero{display:flex;gap:34px;align-items:center;justify-content:center;flex-wrap:wrap;margin:26px 0 26px}
  .gauge{width:210px;height:210px;border-radius:50%;display:grid;place-items:center;background:conic-gradient($GCOL ${SCORE}%,var(--line) 0);position:relative;flex:none}
  .gauge::before{content:"";position:absolute;inset:14px;border-radius:50%;background:var(--bg)}
  .gval{position:relative;text-align:center}
  .gnum{font-size:58px;font-weight:800;line-height:1;color:$GCOL}
  .gnum span{font-size:22px;color:var(--mut)}
  .gpct{font-size:12px;color:var(--mut);margin-top:6px;letter-spacing:1.5px;text-transform:uppercase}
  .stats{display:flex;gap:12px;flex-wrap:wrap;justify-content:center}
  .stat{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px 18px;min-width:88px;text-align:center}
  .stat b{font-size:26px;display:block}
  .stat.ok b{color:#22c55e}.stat.warn b{color:#f59e0b}.stat.fail b{color:#ef4444}.stat.info b{color:#38bdf8}
  .stat small{color:var(--mut);font-size:12px}
  .grade{display:inline-block;padding:5px 16px;border-radius:20px;font-weight:700;font-size:13px;color:#0b0f17;background:$GCOL;margin-top:12px}
  nav{display:flex;gap:8px;flex-wrap:wrap;justify-content:center;margin:8px 0 4px}
  nav a{font-size:12px;color:var(--mut);text-decoration:none;border:1px solid var(--line);border-radius:16px;padding:4px 11px}
  nav a:hover{color:var(--txt);border-color:var(--mut)}
  section{margin-top:24px;scroll-margin-top:16px}
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
  .detail{color:var(--mut);font-size:13px;white-space:pre-line}
  .fix{margin-top:10px;font-size:12px}
  .fix span{color:#f59e0b;font-weight:600}
  .fix code{background:rgba(56,189,248,.09);border:1px solid var(--line);border-radius:5px;padding:2px 6px;color:#38bdf8;font-size:11px;word-break:break-all}
  footer{text-align:center;color:var(--mut);font-size:12px;margin-top:34px;line-height:1.8}
  footer code{color:#38bdf8}
  footer a{color:#38bdf8;text-decoration:none}
</style></head><body>
<header>
  <h1>&#128737;&#65039; Security Score Dashboard</h1>
  <div class="sub">$model &middot; macOS $os &middot; $(L 'skan' 'scanned'): $NOW</div>
</header>
<div class="hero">
  <div class="gauge"><div class="gval"><div class="gnum">$SCORE<span>/100</span></div><div class="gpct">Security Score</div></div></div>
  <div>
    <div class="stats">
      <div class="stat ok"><b>$N_PASS</b><small>OK</small></div>
      <div class="stat warn"><b>$N_WARN</b><small>$(L Uwaga Warn)</small></div>
      <div class="stat fail"><b>$N_FAIL</b><small>$(L Błąd Fail)</small></div>
      <div class="stat info"><b>$N_INFO</b><small>Info</small></div>
    </div>
    <div style="text-align:center"><span class="grade">$GRADE</span></div>
  </div>
</div>
<nav>$NAVLINKS</nav>
$SECTIONS
<footer>
  <b>secure-scan v$VERSION</b> &middot; $TOTAL $(L 'kontroli punktowanych' 'scored checks') + $N_INFO info<br>
  $(L 'Odśwież' 'Refresh'): <code>secure-scan</code> &middot; $(L 'Napraw' 'Fix'): <code>secure-scan --fix</code> &middot;
  <a href="https://github.com/lkolo-prez/secure-scan">github.com/lkolo-prez/secure-scan</a><br>
  <span style="opacity:.7">by Aircloud — Łukasz Kołodziej &middot; MIT</span>
</footer>
</body></html>
HTMLEOF
}

# Buduje linki nawigacji z zebranych nazw kategorii (po wszystkich end_cat)
build_nav() {
  NAVLINKS=""
  local a anchor
  while IFS= read -r a; do
    [ -z "$a" ] && continue
    anchor="$(echo "$a" | tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9-')"
    NAVLINKS="$NAVLINKS<a href='#$anchor'>$a</a>"
  done <<< "$CAT_NAMES"
}
