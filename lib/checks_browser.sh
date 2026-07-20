#!/bin/bash
# lib/checks_browser.sh — zagrożenia przeglądarkowe. Sourced by secure-scan.sh.

# Zlicza rozszerzenia (podkatalogi w folderach Extensions) dla przeglądarki chromium
_count_chromium_ext() {
  local base="$1" total=0 e
  for e in "$base"/*/Extensions "$base"/Extensions; do
    [ -d "$e" ] || continue
    local c; c="$(find "$e" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    total=$((total + c))
  done
  echo "$total"
}

run_browser() {
begin_cat "$(L 'Przeglądarki' 'Browsers')" "&#127760;"

local AS="$HOME/Library/Application Support"
local found=0 line=""

# Chromium-based
local name path
for pair in \
  "Chrome|$AS/Google/Chrome" \
  "Edge|$AS/Microsoft Edge" \
  "Brave|$AS/BraveSoftware/Brave-Browser" \
  "Vivaldi|$AS/Vivaldi" \
  "Opera|$AS/com.operasoftware.Opera"; do
  name="${pair%%|*}"; path="${pair##*|}"
  if [ -d "$path" ]; then
    found=1
    local n; n="$(_count_chromium_ext "$path")"
    line="$line$name: $n $(L 'rozszerzeń' 'extensions')\n"
  fi
done
# Firefox
if [ -d "$HOME/Library/Application Support/Firefox/Profiles" ]; then
  found=1
  local ff; ff="$(find "$HOME/Library/Application Support/Firefox/Profiles" -maxdepth 2 -name '*.xpi' 2>/dev/null | wc -l | tr -d ' ')"
  line="${line}Firefox: $ff $(L 'rozszerzeń' 'extensions')\n"
fi

if [ "$found" -eq 1 ]; then
  add_check "$(L 'Rozszerzenia przeglądarek' 'Browser extensions')" INFO 0 "${line}$(L 'Usuń nieznane rozszerzenia — częsty nośnik adware i wycieku danych.' 'Remove unknown extensions — common adware/data-leak carrier.')" ""
else
  add_check "$(L 'Rozszerzenia przeglądarek' 'Browser extensions')" PASS 4 "$(L 'Nie wykryto profili przeglądarek z rozszerzeniami.' 'No browser profiles with extensions detected.')" ""
fi

# Zarządzane polityki przeglądarek (możliwy hijack / narzucone ustawienia)
local pol=""
[ -f "/Library/Managed Preferences/com.google.Chrome.plist" ] && pol="${pol}Chrome "
[ -f "/Library/Managed Preferences/com.microsoft.Edge.plist" ] && pol="${pol}Edge "
[ -d "/Library/Application Support/Google/Chrome/policies" ] && pol="${pol}Chrome-policies "
if [ -z "$pol" ]; then
  add_check "$(L 'Wymuszone polityki przeglądarek' 'Enforced browser policies')" PASS 5 "$(L 'Brak narzuconych polityk (brak śladów hijacku ustawień).' 'No enforced policies (no settings-hijack signs).')" ""
else
  add_check "$(L 'Wymuszone polityki przeglądarek' 'Enforced browser policies')" WARN 5 "$(L 'Wykryto polityki:' 'Policies found:') $pol— $(L 'zweryfikuj pochodzenie.' 'verify origin.')" ""
fi

# Wtyczki internetowe (klasyczny wektor adware)
local plug=0
[ -d "$HOME/Library/Internet Plug-Ins" ] && plug="$(find "$HOME/Library/Internet Plug-Ins" -maxdepth 1 -mindepth 1 2>/dev/null | grep -civ 'Default Browser' )"
plug="${plug//[^0-9]/}"; plug="${plug:-0}"
if [ "$plug" -eq 0 ]; then
  add_check "$(L 'Wtyczki internetowe' 'Internet plug-ins')" PASS 4 "$(L 'Brak wtyczek użytkownika.' 'No user plug-ins.')" ""
else
  add_check "$(L 'Wtyczki internetowe' 'Internet plug-ins')" WARN 4 "$plug $(L 'wtyczek — przestarzały mechanizm, częsty adware.' 'plug-ins — legacy mechanism, common adware.')" "open ~/Library/Internet\\ Plug-Ins"
fi
end_cat
}
