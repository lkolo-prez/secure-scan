# Changelog

Wszystkie istotne zmiany w projekcie. Format: [Keep a Changelog](https://keepachangelog.com/pl/).

## [1.0.0] — 2026-07-20

### Dodane
- Pierwsze wydanie `secure-scan`.
- 20 kontroli bezpieczeństwa macOS w 5 kategoriach (szyfrowanie i rozruch, sieć i zapora, aktualizacje i ochrona, konta i dostęp, prywatność i malware).
- Security Score 0–100 z wagami wg krytyczności i oceną słowną.
- Wizualny dashboard HTML: gauge, wyniki per-kategoria, karty OK/Uwaga/Błąd, komendy naprawcze.
- Eksport JSON (`--json`) do automatyzacji/CI.
- Tryby `--no-open`, `--help`, `--version`.
- Wszystkie kontrole read-only, bez zależności, bez `sudo`.
