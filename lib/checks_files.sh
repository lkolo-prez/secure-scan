#!/bin/bash
# lib/checks_files.sh — integralność plików. Sourced by secure-scan.sh.

run_files() {
begin_cat "$(L 'Integralność plików' 'File Integrity')" "&#128194;"

# 1. Binaria SUID/SGID poza systemem ----------------------------------------
local suid suid_n
suid="$(find /Applications /usr/local /opt -maxdepth 4 -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20)"
suid_n="$(printf '%s' "$suid" | grep -c . )"
if [ "${suid_n:-0}" -eq 0 ]; then
  add_check "$(L 'Binaria SUID/SGID (poza systemem)' 'SUID/SGID binaries (non-system)')" PASS 6 "$(L 'Brak nietypowych binariów z podwyższonymi uprawnieniami.' 'No unusual elevated-privilege binaries.')" ""
else
  local slist; slist="$(printf '%s' "$suid" | sed 's#.*/##' | head -5 | tr '\n' ' ')"
  add_check "$(L 'Binaria SUID/SGID (poza systemem)' 'SUID/SGID binaries (non-system)')" INFO 0 "${suid_n} $(L 'binariów SUID/SGID (zwykle legalne, np. helpery):' 'SUID/SGID binaries (usually legit, e.g. helpers):') ${slist}" "find /Applications /usr/local /opt -type f -perm -4000"
fi

# 2. Uprawnienia katalogów startowych (nie mogą być world-writable) ---------
local badperm="" sp
for d in /Library/LaunchDaemons /Library/LaunchAgents; do
  [ -d "$d" ] || continue
  sp="$(stat -f '%Sp' "$d" 2>/dev/null)"   # np. drwxr-xr-x
  # znak nr 9 (0-indeks 8) to bit zapisu dla "innych"
  [ "${sp:8:1}" = "w" ] && badperm="$badperm$d "
done
if [ -z "$badperm" ]; then
  add_check "$(L 'Uprawnienia katalogów startowych' 'Launch dir permissions')" PASS 6 "$(L 'Katalogi LaunchDaemons/Agents nie są zapisywalne dla wszystkich.' 'LaunchDaemons/Agents dirs not world-writable.')" ""
else
  add_check "$(L 'Uprawnienia katalogów startowych' 'Launch dir permissions')" FAIL 6 "$(L 'World-writable (malware może dodać persistencję):' 'World-writable (malware could add persistence):') $badperm" "sudo chmod go-w $badperm"
fi

# 3. Pliki z atrybutem kwarantanny w katalogach uruchamialnych --------------
local q; q="$(find "$HOME/Downloads" -maxdepth 1 -type f -exec xattr -p com.apple.quarantine {} \; 2>/dev/null | grep -c . )"
q="${q//[^0-9]/}"; q="${q:-0}"
add_check "$(L 'Pliki w kwarantannie (Pobrane)' 'Quarantined files (Downloads)')" INFO 0 "${q} $(L 'plików ma flagę kwarantanny Gatekeeper (dobrze — będą sprawdzone przy otwarciu).' 'files carry the Gatekeeper quarantine flag (good — checked on open).')" ""

# 4. Katalog /tmp — wykonywalne skrypty (typowa scena malware) --------------
local tmpexec; tmpexec="$(find /tmp /private/tmp -maxdepth 1 -type f \( -name '*.sh' -o -name '*.command' -o -perm -111 \) 2>/dev/null | grep -vE 'com.|/\.' | head -5)"
if [ -z "$tmpexec" ]; then
  add_check "$(L 'Wykonywalne w /tmp' 'Executables in /tmp')" PASS 5 "$(L 'Brak podejrzanych skryptów/binariów w /tmp.' 'No suspicious scripts/binaries in /tmp.')" ""
else
  add_check "$(L 'Wykonywalne w /tmp' 'Executables in /tmp')" WARN 5 "$(L 'Wykonywalne pliki w /tmp — zweryfikuj:' 'Executables in /tmp — verify:')\n$(printf '%s' "$tmpexec" | sed 's#.*/##' | tr '\n' ' ')" "ls -la /tmp"
fi

# 5. Kopie zapasowe Time Machine (odzyskiwanie po ransomware) ---------------
if tmutil destinationinfo 2>/dev/null | grep -qiE 'Kind|Name|Mount'; then
  add_check "$(L 'Kopie zapasowe (Time Machine)' 'Backups (Time Machine)')" INFO 0 "$(L 'Skonfigurowane — dobra ochrona przed ransomware/utratą danych.' 'Configured — good protection against ransomware/data loss.')" ""
else
  add_check "$(L 'Kopie zapasowe (Time Machine)' 'Backups (Time Machine)')" WARN 4 "$(L 'Brak celu Time Machine — bez kopii nie odzyskasz danych po ransomware/awarii.' 'No Time Machine target — no backups to recover from ransomware/failure.')" "$(L 'Ustawienia > Ogólne > Time Machine' 'Settings > General > Time Machine')"
fi

# 6. Klucze prywatne SSH ----------------------------------------------------
local sshk; sshk="$(ls "$HOME/.ssh"/id_* 2>/dev/null | grep -vc '\.pub$')"; sshk="${sshk//[^0-9]/}"; sshk="${sshk:-0}"
if [ "$sshk" -eq 0 ]; then
  add_check "$(L 'Klucze prywatne SSH' 'SSH private keys')" PASS 3 "$(L 'Brak kluczy prywatnych SSH w ~/.ssh.' 'No SSH private keys in ~/.ssh.')" ""
else
  add_check "$(L 'Klucze prywatne SSH' 'SSH private keys')" INFO 0 "$sshk $(L 'kluczy prywatnych — upewnij się, że są chronione hasłem (passphrase).' 'private keys — ensure each is passphrase-protected.')" "ssh-keygen -y -f ~/.ssh/id_ed25519"
fi
end_cat
}
