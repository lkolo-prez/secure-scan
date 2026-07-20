#!/bin/bash
# lib/checks_perf.sh — wydajność, wycieki CPU/RAM. Sourced by secure-scan.sh.

run_perf() {
begin_cat "$(L 'Wydajność i wycieki' 'Performance & Leaks')" "&#128293;"

# 1. Top CPU ----------------------------------------------------------------
local cpu_top cpu_val cpu_name
cpu_top="$(ps -Aceo pcpu,comm -r 2>/dev/null | sed -n '2,4p' | awk '{printf "%s (%s%%)\\n", $2, $1}')"
cpu_val="$(ps -Aceo pcpu,comm -r 2>/dev/null | sed -n '2p' | awk '{print int($1)}')"
cpu_name="$(ps -Aceo pcpu,comm -r 2>/dev/null | sed -n '2p' | awk '{$1="";sub(/^ /,"");print}')"
if [ "${cpu_val:-0}" -ge 90 ]; then
  add_check "$(L 'Obciążenie CPU' 'CPU usage')" WARN 3 "$(L 'Proces zużywa dużo CPU:' 'Process using high CPU:') $cpu_name (${cpu_val}%).\n$(L 'Top 3:' 'Top 3:')\n$cpu_top" "$(L 'Sprawdź w Monitorze aktywności czy to nie zawieszony/kopiący proces.' 'Check Activity Monitor for a hung/mining process.')"
else
  add_check "$(L 'Obciążenie CPU' 'CPU usage')" INFO 0 "$(L 'Top 3 wg CPU:' 'Top 3 by CPU:')\n$cpu_top" ""
fi

# 2. Wycieki pamięci (procesy z bardzo dużym RSS) ---------------------------
local leak_list="" leak=0 rss name
while read -r rss name; do
  [ -z "$rss" ] && continue
  local gb=$(( rss / 1048576 ))   # KB -> GB
  if [ "$gb" -ge 6 ]; then
    leak=$((leak+1)); leak_list="$leak_list$name: ${gb} GB\\n"
  fi
done < <(ps -Aceo rss,comm -m 2>/dev/null | sed -n '2,6p')
if [ "$leak" -eq 0 ]; then
  add_check "$(L 'Zużycie pamięci (wycieki)' 'Memory usage (leaks)')" PASS 4 "$(L 'Brak procesów z podejrzanie dużym RSS (≥6 GB).' 'No processes with suspicious RSS (≥6 GB).')" ""
else
  add_check "$(L 'Zużycie pamięci (wycieki)' 'Memory usage (leaks)')" WARN 4 "$(L 'Procesy z dużym RSS (możliwy wyciek pamięci):' 'High-RSS processes (possible memory leak):')\n$leak_list$(L 'Zrestartuj aplikację jeśli rośnie w czasie.' 'Restart the app if it keeps growing.')" ""
fi

# 3. Presja pamięci / swap --------------------------------------------------
local swap_used
swap_used="$(sysctl -n vm.swapusage 2>/dev/null | grep -oE 'used = [0-9.]+[MG]' | grep -oE '[0-9.]+[MG]')"
local swap_num="${swap_used%[MG]}"; local swap_unit="${swap_used: -1}"
local swap_mb=0
[ "$swap_unit" = "G" ] && swap_mb=$(printf '%.0f' "$(echo "$swap_num" | awk '{print $1*1024}')" 2>/dev/null)
[ "$swap_unit" = "M" ] && swap_mb=$(printf '%.0f' "$swap_num" 2>/dev/null)
if [ "${swap_mb:-0}" -lt 2048 ]; then
  add_check "$(L 'Presja pamięci (swap)' 'Memory pressure (swap)')" PASS 4 "$(L 'Swap w normie' 'Swap normal') (${swap_used:-0}). $(L 'Brak presji pamięci.' 'No memory pressure.')" ""
else
  add_check "$(L 'Presja pamięci (swap)' 'Memory pressure (swap)')" WARN 4 "$(L 'Wysokie użycie swap' 'High swap usage') (${swap_used}). $(L 'System zrzuca RAM na dysk — możliwy wyciek lub za mało RAM.' 'System paging to disk — possible leak or low RAM.')" ""
fi

# 4. Uptime (długość działania — restart czyści wycieki) --------------------
local up; up="$(uptime 2>/dev/null | grep -oE 'up [^,]+(, [0-9]+ hrs)?' | head -1)"
add_check "$(L 'Czas działania (uptime)' 'Uptime')" INFO 0 "$(L 'System działa:' 'System up:') ${up:-?}. $(L 'Okresowy restart czyści wycieki pamięci i stosuje aktualizacje.' 'Periodic restart clears leaks and applies updates.')" ""
end_cat
}
