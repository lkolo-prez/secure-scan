# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/).

## [2.0.0] — 2026-07-20

### Added
- **Modular architecture** (`lib/*.sh`) — framework + 6 check modules + remediation.
- **5 new categories / modules** (now 10 categories, 39 checks):
  - 🧟 Malware & Persistence — suspicious launch items (trojan patterns), cron jobs, known adware/PUP, ClamAV status, Downloads hygiene.
  - 🌍 Browsers — extension counts per browser, enforced policies (hijack signs), internet plug-ins.
  - 🔥 Performance & Leaks — top CPU, high-RSS processes (memory leaks), swap/memory pressure, uptime.
  - 📡 Network Activity — external listening ports, outbound connections, VPN, DNS.
  - 📁 File Integrity — SUID/SGID binaries, launch-dir permissions, quarantine flags, `/tmp` executables.
- **`--fix` auto-hardening** — interactive or `--yes`; enables firewall/stealth/Gatekeeper, disables guest/SSH, sets immediate screen lock. Reversible.
- **Bilingual EN / PL** with auto-detection and `--lang` override.
- **Native macOS notification** with the final result.
- **`INFO` status** for advisory items (not scored).
- **Module selection** via `--only`, category navigation in the dashboard.
- Double-clickable **`secure-scan.command`** launcher.
- Bilingual docs: `README.md` (EN) + `README.pl.md` (PL).

### Changed
- Dashboard: per-category scores, nav links, `INFO` cards, light/dark theme.
- Baseline checks rewritten as the `core` module.

### Fixed
- Division-by-zero on INFO-only categories (bash 3.2 ternary evaluation).
- False positive in launch-dir permission check (symbolic-mode parsing).

## [1.0.0] — 2026-07-20

### Added
- First release: 20 read-only checks, 0–100 Security Score, HTML dashboard, `--json`.
