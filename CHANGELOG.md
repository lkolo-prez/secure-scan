# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/).

## [3.0.0] — 2026-07-21

### Added
- 🖥️ **Native macOS app (SecureScan.app)** — a SwiftUI menu-bar app that shows the Security Score at a glance and a native dashboard (score gauge, per-category breakdown, check list). Buttons: `Scan`, `Fix` (native admin prompt), `Report` (opens the HTML), plus a PL/EN toggle. Built with `swiftc` only — no full Xcode required.
- **`build-app.sh`** — compiles the Swift frontend, bundles the shell engine into `Contents/Resources/engine`, writes `Info.plist`, and ad-hoc-signs `dist/SecureScan.app`.
- **7 new read-only checks** (46 total):
  - `/etc/hosts` redirect tampering (phishing/malware) — flags redirects of sensitive domains.
  - Proxy / PAC detection (traffic-interception risk).
  - File Sharing (SMB/AFP) network exposure.
  - Firewall block-all-incoming state (info).
  - Login-window password hints.
  - Time Machine backups configured (ransomware recovery).
  - SSH private keys present (passphrase reminder).
- CI now compiles and verifies the native app on a macOS runner.

### Changed
- Engine honours `SECURE_SCAN_OUT` to write the HTML report to a writable dir (so it can run from inside the read-only `.app` bundle).
- Docs restructured around the native app (README.md / README.pl.md).

### Fixed
- JSON escaping is now robust against backslashes in data (e.g. `lsof`'s `\x20` in process names), so `--json` is always valid.

## [2.0.0] — 2026-07-20

### Added
- Modular `lib/` architecture, 5 new categories (10 total, 39 checks), `--fix` auto-hardening, bilingual EN/PL, native notifications, `--only`, `.command` launcher, CI.

## [1.0.0] — 2026-07-20

### Added
- First release: 20 read-only checks, 0–100 Security Score, HTML dashboard, `--json`.
