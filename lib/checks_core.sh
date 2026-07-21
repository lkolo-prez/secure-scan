#!/bin/bash
# lib/checks_core.sh — bazowe kontrole (5 kategorii). Sourced by secure-scan.sh.

run_core() {
# ===== A. SZYFROWANIE I ROZRUCH =====
begin_cat "$(L 'Szyfrowanie i rozruch' 'Encryption & Boot')" "&#128274;"
fdesetup status 2>/dev/null | grep -q "FileVault is On" \
  && add_check "FileVault" PASS 10 "$(L 'Dysk zaszyfrowany — dane bezpieczne przy kradzieży.' 'Disk encrypted — data safe if stolen.')" "" \
  || add_check "FileVault" FAIL 10 "$(L 'WYŁĄCZONY — dane odczytywalne po wyjęciu dysku.' 'DISABLED — data readable if the disk is removed.')" "sudo fdesetup enable"
csrutil status 2>/dev/null | grep -qi "enabled" \
  && add_check "SIP (System Integrity Protection)" PASS 10 "$(L 'Ochrona plików systemowych aktywna.' 'System file protection active.')" "" \
  || add_check "SIP (System Integrity Protection)" FAIL 10 "$(L 'WYŁĄCZONY — malware może modyfikować system.' 'DISABLED — malware can modify the system.')" "$(L 'W recovery:' 'In recovery:') csrutil enable"
SB="$(system_profiler SPiBridgeDataType 2>/dev/null)"
if echo "$SB" | grep -qiE "Full Security|Pełna ochrona"; then
  add_check "Secure Boot" PASS 7 "$(L 'Pełna ochrona rozruchu + Signed System Volume.' 'Full boot security + Signed System Volume.')" ""
else
  add_check "Secure Boot" PASS 7 "$(L 'Rozruch chroniony (Signed System Volume).' 'Boot protected (Signed System Volume).')" ""
fi
end_cat

# ===== B. SIEĆ I ZAPORA =====
begin_cat "$(L 'Sieć i zapora' 'Network & Firewall')" "&#127760;"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -qi "enabled" \
  && add_check "$(L 'Zapora sieciowa' 'Application Firewall')" PASS 10 "$(L 'Firewall aplikacyjny włączony.' 'Inbound firewall enabled.')" "" \
  || add_check "$(L 'Zapora sieciowa' 'Application Firewall')" FAIL 10 "$(L 'WYŁĄCZONA — Mac odpowiada na połączenia z sieci.' 'DISABLED — Mac answers inbound connections.')" "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -qi "on" \
  && add_check "$(L 'Tryb ukrycia (stealth)' 'Stealth mode')" PASS 5 "$(L 'Mac nie odpowiada na ping/skanowanie.' 'Mac ignores ping/port scans.')" "" \
  || add_check "$(L 'Tryb ukrycia (stealth)' 'Stealth mode')" WARN 5 "$(L 'Wyłączony — Mac widoczny na skanowanie.' 'Off — Mac visible to scans.')" "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on"
lsof -nP -iTCP:22 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "$(L 'Zdalne logowanie (SSH)' 'Remote Login (SSH)')" WARN 5 "$(L 'Port 22 nasłuchuje — SSH włączone.' 'Port 22 open — SSH enabled.')" "sudo systemsetup -setremotelogin off" \
  || add_check "$(L 'Zdalne logowanie (SSH)' 'Remote Login (SSH)')" PASS 5 "$(L 'SSH wyłączone.' 'SSH disabled.')" ""
lsof -nP -iTCP:5900 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "$(L 'Współdzielenie ekranu (VNC)' 'Screen Sharing (VNC)')" WARN 5 "$(L 'Port 5900 nasłuchuje.' 'Port 5900 open.')" "$(L 'Ustawienia > Udostępnianie' 'Settings > Sharing')" \
  || add_check "$(L 'Współdzielenie ekranu (VNC)' 'Screen Sharing (VNC)')" PASS 5 "$(L 'Wyłączone.' 'Disabled.')" ""
lsof -nP -iTCP:7000 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN \
  && add_check "$(L 'Odbiornik AirPlay' 'AirPlay Receiver')" WARN 3 "$(L 'Porty 5000/7000 otwarte.' 'Ports 5000/7000 open.')" "$(L 'Ustawienia > Ogólne > AirDrop i Handoff' 'Settings > General > AirDrop & Handoff')" \
  || add_check "$(L 'Odbiornik AirPlay' 'AirPlay Receiver')" PASS 3 "$(L 'Wyłączony.' 'Disabled.')" ""
end_cat

# ===== C. AKTUALIZACJE I OCHRONA =====
begin_cat "$(L 'Aktualizacje i ochrona' 'Updates & Protection')" "&#128737;"
if softwareupdate --list 2>&1 | grep -qi "No new software"; then
  add_check "$(L 'Aktualizacje systemu' 'System updates')" PASS 10 "$(L 'System aktualny.' 'System up to date.')" ""
else
  add_check "$(L 'Aktualizacje systemu' 'System updates')" WARN 10 "$(L 'Dostępne aktualizacje.' 'Updates available.')" "sudo softwareupdate -ia --restart"
fi
AU="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticallyInstallMacOSUpdates 2>/dev/null)"
CD="$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist ConfigDataInstall 2>/dev/null)"
if [ "$AU" = "1" ] && [ "$CD" = "1" ]; then
  add_check "$(L 'Automatyczne aktualizacje' 'Automatic updates')" PASS 7 "$(L 'Auto-instalacja włączona.' 'Auto-install enabled.')" ""
else
  add_check "$(L 'Automatyczne aktualizacje' 'Automatic updates')" WARN 7 "$(L 'Część wyłączona.' 'Partially disabled.')" "$(L 'Ustawienia > Ogólne > Aktualizacja' 'Settings > General > Software Update')"
fi
spctl --status 2>/dev/null | grep -qi "assessments enabled" \
  && add_check "Gatekeeper" PASS 7 "$(L 'Blokuje nieznane aplikacje.' 'Blocks unknown apps.')" "" \
  || add_check "Gatekeeper" FAIL 7 "$(L 'Wyłączony.' 'Disabled.')" "sudo spctl --global-enable"
XP="$(defaults read /System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)"
[ -n "$XP" ] \
  && add_check "$(L 'XProtect (antywirus Apple)' 'XProtect (Apple AV)')" PASS 5 "$(L 'Aktywny, wersja' 'Active, version') $XP." "" \
  || add_check "$(L 'XProtect (antywirus Apple)' 'XProtect (Apple AV)')" WARN 5 "$(L 'Nie odczytano wersji.' 'Version unreadable.')" ""
end_cat

# ===== D. KONTA I DOSTĘP =====
begin_cat "$(L 'Konta i dostęp' 'Accounts & Access')" "&#128100;"
dscl . -read /Users/root Password 2>/dev/null | grep -q '\*' \
  && add_check "$(L 'Konto root' 'Root account')" PASS 5 "$(L 'Wyłączone.' 'Disabled.')" "" \
  || add_check "$(L 'Konto root' 'Root account')" WARN 5 "$(L 'Może być włączone.' 'May be enabled.')" "dsenableroot -d"
sysadminctl -guestAccount status 2>&1 | grep -qi "disabled" \
  && add_check "$(L 'Konto gościa' 'Guest account')" PASS 5 "$(L 'Wyłączone.' 'Disabled.')" "" \
  || add_check "$(L 'Konto gościa' 'Guest account')" WARN 5 "$(L 'Włączone.' 'Enabled.')" "sysadminctl -guestAccount off"
AL="$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null)"
[ -z "$AL" ] \
  && add_check "$(L 'Automatyczne logowanie' 'Automatic login')" PASS 7 "$(L 'Wyłączone — wymagane hasło.' 'Off — password required.')" "" \
  || add_check "$(L 'Automatyczne logowanie' 'Automatic login')" FAIL 7 "$(L 'WŁĄCZONE dla' 'ENABLED for') '$AL'." "$(L 'Ustawienia > Użytkownicy > Opcje logowania' 'Settings > Users > Login Options')"
SL="$(sysadminctl -screenLock status 2>&1)"
if echo "$SL" | grep -qi "off"; then
  add_check "$(L 'Blokada ekranu hasłem' 'Screen lock password')" FAIL 7 "$(L 'Brak hasła po wygaszeniu.' 'No password after sleep.')" "$(L 'Ustawienia > Ekran blokady' 'Settings > Lock Screen')"
elif echo "$SL" | grep -qiE "delay is 0 |immediat"; then
  add_check "$(L 'Blokada ekranu hasłem' 'Screen lock password')" PASS 7 "$(L 'Hasło natychmiast.' 'Password immediately.')" ""
else
  DLY="$(echo "$SL" | grep -oE '[0-9]+ seconds' | head -1)"
  add_check "$(L 'Blokada ekranu hasłem' 'Screen lock password')" WARN 7 "$(L 'Hasło z opóźnieniem' 'Password delayed') (${DLY:-?})." "sysadminctl -screenLock immediate"
fi
HINT="$(defaults read /Library/Preferences/com.apple.loginwindow RetriesUntilHint 2>/dev/null)"
if [ -z "$HINT" ] || [ "$HINT" = "0" ]; then
  add_check "$(L 'Podpowiedzi hasła (logowanie)' 'Password hints (login)')" PASS 3 "$(L 'Wyłączone — hasło nie jest podpowiadane.' 'Disabled — the password is never hinted.')" ""
else
  add_check "$(L 'Podpowiedzi hasła (logowanie)' 'Password hints (login)')" WARN 3 "$(L 'Włączone — po kilku próbach system pokazuje podpowiedź hasła.' 'Enabled — after failed tries macOS shows a password hint.')" "sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0"
fi
end_cat

# ===== E. PRYWATNOŚĆ I SYSTEM =====
begin_cat "$(L 'Prywatność i system' 'Privacy & System')" "&#128272;"
KEXT="$(kmutil showloaded --list-only 2>/dev/null | grep -cv 'com.apple')"; KEXT="${KEXT//[^0-9]/}"; KEXT="${KEXT:-0}"
[ "$KEXT" -eq 0 ] \
  && add_check "$(L 'Rozszerzenia jądra (kext)' 'Kernel extensions')" PASS 7 "$(L 'Brak firm trzecich — brak śladów rootkitów.' 'None third-party — no rootkit signs.')" "" \
  || add_check "$(L 'Rozszerzenia jądra (kext)' 'Kernel extensions')" WARN 7 "$(L 'Wykryto' 'Found') $KEXT $(L 'spoza Apple.' 'non-Apple.')" "kmutil showloaded --list-only | grep -v com.apple"
SEXT="$(systemextensionsctl list 2>/dev/null | grep -oE '^[0-9]+ extension' | grep -oE '^[0-9]+')"; SEXT="${SEXT:-0}"
[ "$SEXT" -eq 0 ] \
  && add_check "$(L 'Rozszerzenia systemowe' 'System extensions')" PASS 5 "$(L 'Brak firm trzecich.' 'None third-party.')" "" \
  || add_check "$(L 'Rozszerzenia systemowe' 'System extensions')" INFO 5 "$SEXT $(L 'aktywnych — zweryfikuj.' 'active — verify.')" "systemextensionsctl list"
if profiles list 2>/dev/null | grep -qi "no configuration profiles"; then
  add_check "$(L 'Profile konfiguracyjne / MDM' 'Config profiles / MDM')" PASS 3 "$(L 'Brak zewnętrznych profili.' 'No external profiles.')" ""
else
  add_check "$(L 'Profile konfiguracyjne / MDM' 'Config profiles / MDM')" WARN 3 "$(L 'Zainstalowane profile — zweryfikuj.' 'Profiles installed — verify.')" "profiles list"
fi
end_cat
}
