#!/bin/bash
# lib/checks_downloads.sh — skan pobranych plików i skryptów. Sourced by secure-scan.sh.

run_downloads() {
begin_cat "$(L 'Pobrane pliki i skrypty' 'Downloads & scripts')" "&#128229;"
local DL="$HOME/Downloads"

if [ ! -d "$DL" ]; then
  add_check "$(L 'Katalog Pobrane' 'Downloads folder')" INFO 0 "$(L 'Brak katalogu ~/Downloads.' 'No ~/Downloads folder.')" ""
  end_cat; return
fi

# 1. Niepodpisane / nienotaryzowane instalatory (.app/.pkg) -----------------
local unsigned=0 checked=0 item ulist=""
while IFS= read -r item; do
  [ -e "$item" ] || continue
  checked=$((checked+1))
  if ! spctl -a -t exec "$item" >/dev/null 2>&1 && ! spctl -a -t install "$item" >/dev/null 2>&1; then
    unsigned=$((unsigned+1)); ulist="$ulist$(basename "$item")\n"
  fi
done < <(find "$DL" -maxdepth 1 \( -name '*.app' -o -name '*.pkg' \) 2>/dev/null | head -25)
if [ "$checked" -eq 0 ]; then
  add_check "$(L 'Podpis instalatorów' 'Installer signatures')" PASS 7 "$(L 'Brak instalatorów .app/.pkg w Pobranych.' 'No .app/.pkg installers in Downloads.')" ""
elif [ "$unsigned" -eq 0 ]; then
  add_check "$(L 'Podpis instalatorów' 'Installer signatures')" PASS 7 "$checked $(L 'instalatorów — wszystkie podpisane/notaryzowane.' 'installers — all signed/notarized.')" ""
else
  add_check "$(L 'Podpis instalatorów' 'Installer signatures')" FAIL 7 "$unsigned/$checked $(L 'NIEPODPISANYCH — potencjalne malware:' 'UNSIGNED — potential malware:')\n$ulist" "$(L 'Nie otwieraj niepodpisanych instalatorów.' 'Do not open unsigned installers.')"
fi

# 2. Skrypty i wykonywalne w Pobranych --------------------------------------
local scr; scr="$(find "$DL" -maxdepth 2 -type f \( -name '*.sh' -o -name '*.command' -o -name '*.py' -o -name '*.js' -o -name '*.rb' -o -name '*.pl' -o -perm -111 \) 2>/dev/null | grep -vE '\.(app)/' | head -30)"
local scrn; scrn="$(printf '%s' "$scr" | grep -c . )"; scrn="${scrn//[^0-9]/}"; scrn="${scrn:-0}"
if [ "$scrn" -eq 0 ]; then
  add_check "$(L 'Skrypty w Pobranych' 'Scripts in Downloads')" PASS 6 "$(L 'Brak skryptów/wykonywalnych w Pobranych.' 'No scripts/executables in Downloads.')" ""
else
  add_check "$(L 'Skrypty w Pobranych' 'Scripts in Downloads')" WARN 6 "$scrn $(L 'skryptów/wykonywalnych — uruchamiaj tylko z zaufanych źródeł:' 'scripts/executables — run only from trusted sources:')\n$(printf '%s' "$scr" | sed 's#.*/##' | head -6 | tr '\n' ' ')" "$(L 'Przejrzyj zawartość przed uruchomieniem.' 'Review contents before running.')"
fi

# 3. Maskarada rozszerzenia (plik „dokument", a faktycznie kod) -------------
local masq=0 mlist="" f ft
while IFS= read -r f; do
  [ -f "$f" ] || continue
  ft="$(file -b "$f" 2>/dev/null)"
  case "$ft" in
    *executable*|*"shell script"*|*"Mach-O"*|*"script text executable"*)
      masq=$((masq+1)); mlist="$mlist$(basename "$f") [$ft]\n" ;;
  esac
done < <(find "$DL" -maxdepth 2 -type f \( -iname '*.pdf' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.doc' -o -iname '*.docx' -o -iname '*.txt' \) 2>/dev/null | head -40)
if [ "$masq" -eq 0 ]; then
  add_check "$(L 'Maskarada rozszerzeń' 'Extension masquerade')" PASS 8 "$(L 'Brak plików „dokumentów", które są w rzeczywistości kodem.' 'No document-looking files that are actually code.')" ""
else
  add_check "$(L 'Maskarada rozszerzeń' 'Extension masquerade')" FAIL 8 "$masq $(L 'plików udaje dokumenty a to KOD — silny sygnał malware:' 'files masquerade as documents but are CODE — strong malware signal:')\n$mlist" "$(L 'Usuń natychmiast, nie otwieraj.' 'Delete immediately, do not open.')"
fi

# 4. Higiena kwarantanny ----------------------------------------------------
local total quar
total="$(find "$DL" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
quar="$(find "$DL" -maxdepth 1 -type f -exec xattr -p com.apple.quarantine {} \; 2>/dev/null | grep -c . )"
add_check "$(L 'Higiena Pobranych' 'Downloads hygiene')" INFO 0 "$total $(L 'plików,' 'files,') $quar $(L 'z flagą kwarantanny. Regularnie czyść stare pobrania.' 'quarantined. Clear old downloads regularly.')" ""
end_cat
}
