#!/bin/bash
# lib/checks_network.sh — aktywność sieciowa. Sourced by secure-scan.sh.

run_network() {
begin_cat "$(L 'Aktywność sieciowa' 'Network Activity')" "&#128225;"

# 1. Porty nasłuchujące na zewnątrz -----------------------------------------
local listen listen_n
listen="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -vE '127.0.0.1|\[::1\]' | awk 'NR>1{print $1" :"$9}' | sed 's/.*://' | sort -u)"
listen_n="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -vE '127.0.0.1|\[::1\]' | grep -c LISTEN)"
local ltop; ltop="$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -vE '127.0.0.1|\[::1\]' | awk 'NR>1{print $1}' | sort -u | head -6 | tr '\n' ' ')"
if [ "${listen_n:-0}" -le 2 ]; then
  add_check "$(L 'Porty nasłuchujące (zewnętrzne)' 'Listening ports (external)')" PASS 6 "$(L 'Minimalna powierzchnia ataku:' 'Minimal attack surface:') ${listen_n} $(L 'usług.' 'services.')" ""
else
  add_check "$(L 'Porty nasłuchujące (zewnętrzne)' 'Listening ports (external)')" INFO 0 "${listen_n} $(L 'usług nasłuchuje na zewnątrz:' 'services listening externally:') ${ltop}\n$(L 'Wyłącz nieużywane (AirPlay, udostępnianie).' 'Disable unused ones (AirPlay, sharing).')" "lsof -nP -iTCP -sTCP:LISTEN"
fi

# 2. Połączenia wychodzące ---------------------------------------------------
local est; est="$(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep -c ESTABLISHED)"
local etop; etop="$(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR>1{print $1}' | sort | uniq -c | sort -rn | head -4 | awk '{printf "%s (%s)\\n",$2,$1}')"
add_check "$(L 'Połączenia wychodzące' 'Outbound connections')" INFO 0 "${est} $(L 'aktywnych połączeń. Najwięcej:' 'active connections. Top:')\n${etop}" ""

# 3. VPN ---------------------------------------------------------------------
local vpn_if vpn_proc
vpn_if="$(ifconfig 2>/dev/null | grep -cE '^utun[0-9]')"
vpn_proc="$(pgrep -l -f -i 'wireguard|globalprotect|openvpn|azurevpn|tunnelblick|nordvpn|proton' 2>/dev/null | awk '{print $2}' | sort -u | tr '\n' ' ')"
if [ -n "$vpn_proc" ]; then
  add_check "VPN" INFO 0 "$(L 'Wykryto klienta VPN:' 'VPN client detected:') ${vpn_proc}($(L 'interfejsów utun:' 'utun ifaces:') ${vpn_if})." ""
else
  add_check "VPN" INFO 0 "$(L 'Brak aktywnego klienta VPN. W publicznym Wi-Fi rozważ VPN.' 'No active VPN client. On public Wi-Fi consider a VPN.')" ""
fi

# 4. DNS ---------------------------------------------------------------------
local dns; dns="$(scutil --dns 2>/dev/null | awk '/nameserver\[0\]/{print $3; exit}')"
add_check "$(L 'Serwer DNS' 'DNS resolver')" INFO 0 "$(L 'Podstawowy DNS:' 'Primary DNS:') ${dns:-?}. $(L 'Rozważ szyfrowany DNS (np. 1.1.1.1 / DoH) dla prywatności.' 'Consider encrypted DNS (e.g. 1.1.1.1 / DoH) for privacy.')" ""
end_cat
}
