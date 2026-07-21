# 🛡️ secure-scan

> **Zaawansowany audyt bezpieczeństwa macOS** — natywna aplikacja w pasku menu (**`.app`**) i CLI: 53 kontrole tylko-do-odczytu w 11 kategoriach, **Security Score (0–100)**, **utwardzanie jednym kliknięciem** i **automatyczna blokada groźnych domen**.

[🇬🇧 English](README.md) · **🇵🇱 Polski** — Marka **Aircloud — Łukasz Kołodziej** · MIT

[![CI](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml)
![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![platform](https://img.shields.io/badge/platform-macOS%20(Apple%20Silicon%20%26%20Intel)-000?logo=apple)
![license](https://img.shields.io/badge/license-MIT-blue)
![deps](https://img.shields.io/badge/zależności-brak-success)
![bilingual](https://img.shields.io/badge/języki-EN%20%2F%20PL-orange)

Jeden projekt, zero zależności. **Wszystkie skany są read-only** — niczego nie zmieniają i nie wymagają `sudo`. Uruchamiasz, dostajesz wynik, a `--fix` utwardza system za Ciebie (po Twoim potwierdzeniu).

---

## ✨ Funkcje

- 🖥️ **Natywna aplikacja macOS** — apka SwiftUI w pasku menu: wynik na pierwszy rzut oka, natywny dashboard, przyciski `Skanuj`/`Napraw`/`Raport`, **sparkline trendu**, przełączniki **Start przy logowaniu** i **Ochrona sieci**, ikona i przełącznik PL/EN. Budowana samym `swiftc`.
- 🌐 **Ochrona sieci** — jeden przełącznik instaluje utrzymywaną blocklistę (80 tys.+ domen malware/phishing/trackery) do `/etc/hosts`, blokując groźne strony systemowo. W pełni odwracalne.
- 📥 **Skan pobranych** — wykrywa niepodpisane instalatory, skrypty i maskaradę rozszerzeń (malware) w `~/Downloads`.
- 🔐 **Zero-trust** — konto o minimalnych uprawnieniach, audyt uprawnień TCC, zasada „nie ufaj pobranym".
- ✅ **Testowane i audytowane** — zestaw 39 testów + self-audit bezpieczeństwa (shellcheck, skan sekretów, groźne wzorce) na CI.
- **53 kontrole** w **11 kategoriach** (system, malware/persistencja, przeglądarki, wydajność/wycieki, sieć, integralność plików, pobrane)
- **Security Score 0–100** z wagami wg krytyczności + wyniki per-kategoria
- Wizualny **dashboard HTML** (gauge, nawigacja, karty OK/Uwaga/Błąd/Info, komendy naprawcze), tryb jasny i ciemny
- **Auto-naprawa `--fix`** — włącza zaporę, stealth, Gatekeeper, wyłącza gościa, ustawia natychmiastową blokadę… interaktywnie lub `--yes`
- **Dwujęzyczność EN / PL** (auto-wykrywanie, zmiana przez `--lang`)
- Natywna **notyfikacja macOS** z wynikiem
- **Eksport JSON** (`--json`) do CI/automatyzacji
- Klikany dwukrotnie launcher **`.command`** dla osób nietechnicznych

## 🖥️ Natywna aplikacja (zalecane)

Zbuduj klikalną apkę w pasku menu (wymaga tylko Xcode Command Line Tools — `xcode-select --install`):

```bash
git clone https://github.com/lkolo-prez/secure-scan.git
cd secure-scan
./build-app.sh
open dist/SecureScan.app          # w pasku menu pojawi się 🛡 z Twoim wynikiem
cp -R dist/SecureScan.app /Applications/   # opcjonalnie: zainstaluj
```

Apka ma wbudowany silnik skanujący i uruchamia go przez `--json`; wynik, rozbicie i naprawa są w natywnym panelu SwiftUI. `Napraw` wywołuje standardowy monit macOS o hasło administratora. Pierwsze uruchomienie niepodpisanej apki: prawy przycisk → **Otwórz** (lub *Ustawienia → Prywatność i ochrona → Otwórz mimo to*).

> Obecnie budowana dla **Apple Silicon (arm64)**. Dla Intela: `MACOS_TARGET=x86_64-apple-macos14.0 ./build-app.sh`.

## 🚀 Szybki start (CLI)

```bash
./secure-scan.sh                  # z sklonowanego repo
```

albo instalacja CLI do `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/install.sh | bash
secure-scan
```

## 🧭 Użycie

```
secure-scan                       # skan + dashboard HTML (otwiera przeglądarkę)
secure-scan --fix                 # utwardzanie (pyta przed każdą zmianą)
secure-scan --fix --yes           # utwardzanie bez pytań
secure-scan --protect             # włącz ochronę sieci (blokada groźnych domen)
secure-scan --unprotect           # wyłącz ochronę sieci
secure-scan --json                # wynik JSON (CI)
secure-scan --lang en|pl          # wymuś język
secure-scan --only core,malware   # tylko wybrane moduły
secure-scan --no-open             # nie otwieraj przeglądarki
secure-scan --help | --version
```

Moduły: `core`, `malware`, `browser`, `perf`, `network`, `files`, `downloads`.

## 🌐 Ochrona sieci (blokada groźnych stron)

```bash
secure-scan --protect     # instaluje blocklistę do /etc/hosts (wymaga administratora)
secure-scan --unprotect   # usuwa ją i przywraca /etc/hosts
```

Pobiera renomowaną, utrzymywaną listę hosts (malware + phishing + trackery, ~80 tys. domen) z wbudowanym fallbackiem offline i zapisuje ją w wyraźnie oznaczonym, odwracalnym bloku w `/etc/hosts`, po czym odświeża DNS. Aplikacja udostępnia to jako przełącznik **Ochrona sieci**.

## 🔍 Co sprawdza

| Kategoria | Kontrole |
|---|---|
| 🔐 **Szyfrowanie i rozruch** | FileVault, SIP, Secure Boot / Signed System Volume |
| 🌐 **Sieć i zapora** | Zapora aplikacyjna, tryb stealth, SSH, Screen Sharing (VNC), odbiornik AirPlay |
| 🛡️ **Aktualizacje i ochrona** | Aktualizacje systemu, auto-updates, Gatekeeper, XProtect |
| 👤 **Konta i dostęp** | Root, gość, automatyczne logowanie, hasło blokady ekranu, podpowiedzi hasła, **minimalne uprawnienia (zero-trust)** |
| 🔒 **Prywatność i system** | Rozszerzenia jądra, rozszerzenia systemowe, profile / MDM, **audyt uprawnień TCC** |
| 🧟 **Malware i persistencja** | Podejrzane elementy startowe (wzorce trojanów), cron, znany adware/PUP, status ClamAV, higiena Pobranych, **manipulacja `/etc/hosts`** |
| 🌍 **Przeglądarki** | Liczba rozszerzeń per przeglądarka, wymuszone polityki (ślady hijacku), wtyczki internetowe |
| 🔥 **Wydajność i wycieki** | Top CPU, procesy z dużym RSS (wycieki pamięci), presja swap, uptime |
| 📡 **Aktywność sieciowa** | Porty nasłuchujące, połączenia wychodzące, VPN, DNS, proxy/PAC, ekspozycja File Sharing, block-all zapory, **ochrona sieci (blokada domen)** |
| 📁 **Integralność plików** | Binaria SUID/SGID, uprawnienia katalogów startowych, kwarantanna, wykonywalne w `/tmp`, kopie Time Machine, klucze SSH |
| 📥 **Pobrane i skrypty** | **Niepodpisane instalatory, skrypty/wykonywalne w Pobranych, maskarada rozszerzeń (malware), higiena kwarantanny** |

## 🔧 Auto-naprawa (`--fix`)

`--fix` sprawdza każdy element utwardzania; jeśli już jest bezpiecznie — pomija, w przeciwnym razie pyta przed zmianą (lub użyj `--yes`):

```bash
secure-scan --fix          # interaktywnie
secure-scan --fix --yes    # zastosuj wszystko
```

Włącza: zaporę, stealth, Gatekeeper · wyłącza: konto gościa, zdalne logowanie (SSH) · ustawia: natychmiastową blokadę ekranu. Wszystko odwracalne.

## 📊 Punktacja

Każda punktowana kontrola ma **wagę** wg krytyczności (FileVault/zapora = 10, AirPlay = 3). `UWAGA` daje połowę, `BŁĄD` zero, wpisy `INFO` są doradcze i nie wpływają na wynik.

| Wynik | Ocena |
|---|---|
| 90–100 | Bardzo dobry |
| 75–89 | Dobry |
| 60–74 | Do poprawy |
| < 60 | Słaby |

## ⚠️ Zastrzeżenie

Skany są **read-only** i niczego nie modyfikują. `--fix` uruchamia tylko akcje, które zatwierdzisz. Wynik to wskaźnik higieny bezpieczeństwa, nie gwarancja. Używasz na własną odpowiedzialność.

## 🧪 Rozwój i testy

```bash
bash tests/run-tests.sh          # 39 testów jednostkowych/integracyjnych (bez zależności)
bash scripts/security-audit.sh   # self-audit: shellcheck, skan sekretów, groźne wzorce
```

CI uruchamia oba przy każdym push, a następnie buduje `SecureScan.app` i `.dmg` na runnerze macOS.

## 📄 Licencja

MIT © 2026 **Aircloud — Łukasz Kołodziej** — patrz [LICENSE](LICENSE). Open source; wkład mile widziany.
