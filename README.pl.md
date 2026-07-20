# 🛡️ secure-scan

> **Zaawansowany audyt bezpieczeństwa macOS** — 39 kontroli tylko-do-odczytu w 10 kategoriach, **Security Score (0–100)**, samodzielny dashboard HTML i **utwardzanie systemu jednym poleceniem**.

[🇬🇧 English](README.md) · **🇵🇱 Polski**

[![CI](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml)
![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![platform](https://img.shields.io/badge/platform-macOS%20(Apple%20Silicon%20%26%20Intel)-000?logo=apple)
![license](https://img.shields.io/badge/license-MIT-blue)
![deps](https://img.shields.io/badge/zależności-brak-success)
![bilingual](https://img.shields.io/badge/języki-EN%20%2F%20PL-orange)

Jeden projekt, zero zależności. **Wszystkie skany są read-only** — niczego nie zmieniają i nie wymagają `sudo`. Uruchamiasz, dostajesz wynik, a `--fix` utwardza system za Ciebie (po Twoim potwierdzeniu).

---

## ✨ Funkcje

- **39 kontroli** w **10 kategoriach** (system, malware/persistencja, przeglądarki, wydajność/wycieki, sieć, integralność plików)
- **Security Score 0–100** z wagami wg krytyczności + wyniki per-kategoria
- Wizualny **dashboard HTML** (gauge, nawigacja, karty OK/Uwaga/Błąd/Info, komendy naprawcze), tryb jasny i ciemny
- **Auto-naprawa `--fix`** — włącza zaporę, stealth, Gatekeeper, wyłącza gościa, ustawia natychmiastową blokadę… interaktywnie lub `--yes`
- **Dwujęzyczność EN / PL** (auto-wykrywanie, zmiana przez `--lang`)
- Natywna **notyfikacja macOS** z wynikiem
- **Eksport JSON** (`--json`) do CI/automatyzacji
- Klikany dwukrotnie launcher **`.command`** dla osób nietechnicznych

## 🚀 Szybki start

```bash
git clone https://github.com/lkolo-prez/secure-scan.git
cd secure-scan
./secure-scan.sh
```

albo instalacja do `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/install.sh | bash
secure-scan
```

## 🧭 Użycie

```
secure-scan                       # skan + dashboard HTML (otwiera przeglądarkę)
secure-scan --fix                 # utwardzanie (pyta przed każdą zmianą)
secure-scan --fix --yes           # utwardzanie bez pytań
secure-scan --json                # wynik JSON (CI)
secure-scan --lang en|pl          # wymuś język
secure-scan --only core,malware   # tylko wybrane moduły
secure-scan --no-open             # nie otwieraj przeglądarki
secure-scan --help | --version
```

Moduły: `core`, `malware`, `browser`, `perf`, `network`, `files`.

## 🔍 Co sprawdza

| Kategoria | Kontrole |
|---|---|
| 🔐 **Szyfrowanie i rozruch** | FileVault, SIP, Secure Boot / Signed System Volume |
| 🌐 **Sieć i zapora** | Zapora aplikacyjna, tryb stealth, SSH, Screen Sharing (VNC), odbiornik AirPlay |
| 🛡️ **Aktualizacje i ochrona** | Aktualizacje systemu, auto-updates, Gatekeeper, XProtect |
| 👤 **Konta i dostęp** | Root, gość, automatyczne logowanie, hasło blokady ekranu |
| 🔒 **Prywatność i system** | Rozszerzenia jądra, rozszerzenia systemowe, profile / MDM |
| 🧟 **Malware i persistencja** | Podejrzane elementy startowe (wzorce trojanów), cron, znany adware/PUP, status ClamAV, higiena Pobranych |
| 🌍 **Przeglądarki** | Liczba rozszerzeń per przeglądarka, wymuszone polityki (ślady hijacku), wtyczki internetowe |
| 🔥 **Wydajność i wycieki** | Top CPU, procesy z dużym RSS (wycieki pamięci), presja swap, uptime |
| 📡 **Aktywność sieciowa** | Porty nasłuchujące, połączenia wychodzące, VPN, serwer DNS |
| 📁 **Integralność plików** | Binaria SUID/SGID, uprawnienia katalogów startowych, kwarantanna, wykonywalne w `/tmp` |

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

## 📄 Licencja

MIT © 2026 — patrz [LICENSE](LICENSE).
