# 🛡️ secure-scan

> Lekki audyt bezpieczeństwa macOS z wizualnym **Security Score** i dashboardem HTML.
> A lightweight macOS security audit that computes a **Security Score (0–100)** and renders a self-contained HTML dashboard.

![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![platform](https://img.shields.io/badge/platform-macOS%20(Apple%20Silicon%20%26%20Intel)-000?logo=apple)
![license](https://img.shields.io/badge/license-MIT-blue)
![deps](https://img.shields.io/badge/dependencies-none-success)

Jeden skrypt, zero zależności, **wszystkie kontrole są read-only** — nic nie modyfikuje w systemie i nie wymaga `sudo`. Uruchamiasz, dostajesz wynik i konkretne komendy naprawcze.

---

## ✨ Funkcje / Features

- **20 kontroli** bezpieczeństwa w **5 kategoriach**
- **Security Score 0–100** z wagami wg krytyczności + ocena słowna
- Wizualny **dashboard HTML** (gauge, wyniki per-kategoria, karty OK/Uwaga/Błąd)
- Przy każdym problemie — **gotowa komenda naprawcza**
- Eksport **JSON** (`--json`) do CI / automatyzacji
- **Bez zależności** (czysty `bash` + wbudowane narzędzia macOS), **read-only**, bez `sudo`

## 🚀 Szybki start / Quick start

```bash
git clone https://github.com/lkolo-prez/secure-scan.git
cd secure-scan
./secure-scan.sh
```

albo jedną linijką / or one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/secure-scan.sh -o secure-scan.sh && bash secure-scan.sh
```

Dashboard zapisze się jako `security-dashboard.html` i otworzy w przeglądarce.

## 🧭 Użycie / Usage

```
./secure-scan.sh              # skan + dashboard HTML (otwiera przeglądarkę)
./secure-scan.sh --no-open    # nie otwieraj przeglądarki
./secure-scan.sh --json       # wynik jako JSON (CI / automatyzacja)
./secure-scan.sh --help       # pomoc
./secure-scan.sh --version    # wersja
```

## 🔍 Co jest sprawdzane / Checks

| Kategoria | Kontrola |
|---|---|
| 🔐 **Szyfrowanie i rozruch** | FileVault, SIP, Secure Boot / Signed System Volume |
| 🌐 **Sieć i zapora** | Zapora aplikacyjna, tryb stealth, SSH, Screen Sharing (VNC), odbiornik AirPlay |
| 🛡️ **Aktualizacje i ochrona** | Aktualizacje systemu, auto-updates, Gatekeeper, XProtect |
| 👤 **Konta i dostęp** | Konto root, konto gościa, auto-login, blokada ekranu hasłem |
| 🔍 **Prywatność i malware** | Rozszerzenia jądra (kext), rozszerzenia systemowe, znany adware/PUP, profile MDM |

## 📊 Punktacja / Scoring

Każda kontrola ma **wagę** wg krytyczności (np. FileVault i firewall = 10, AirPlay = 3).
Wynik = `zdobyte / możliwe × 100`. Status `UWAGA` daje połowę punktów, `BŁĄD` — zero.

| Wynik | Ocena |
|---|---|
| 90–100 | Bardzo dobry |
| 75–89 | Dobry |
| 60–74 | Do poprawy |
| < 60 | Słaby |

## 🤖 JSON w CI / JSON output

```bash
./secure-scan.sh --json | jq '.score'
```

```json
{
  "version": "1.0.0",
  "score": 80,
  "grade": "Dobry",
  "pass": 14, "warn": 5, "fail": 1,
  "checks": [ { "category": "...", "name": "...", "status": "PASS", "weight": 10, "detail": "..." } ]
}
```

## ⚠️ Uwaga / Disclaimer

Narzędzie **wyłącznie odczytuje** stan systemu i **niczego nie zmienia**. Komendy naprawcze są jedynie sugerowane — uruchamiasz je samodzielnie i świadomie. Wynik to wskazówka higieny bezpieczeństwa, nie gwarancja.

## 🤝 Wkład / Contributing

Pull requesty mile widziane — nowe kontrole, wsparcie języków, poprawki. Trzymaj kontrole **read-only** i bez zależności zewnętrznych.

## 📄 Licencja / License

MIT © 2026 — patrz [LICENSE](LICENSE).
