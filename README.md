<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# 🛡️ secure-scan

> **Advanced macOS security auditor** — a native menu-bar **`.app`** (and CLI) that runs 53 read-only checks across 11 categories, shows a **Security Score (0–100)**, offers **one-click auto-hardening**, and can **auto-block malicious domains**.

**🇬🇧 English** · [🇵🇱 Polski](README.pl.md) — Made by **Aircloud — Łukasz Kołodziej** · MIT

[![CI](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml)
![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![platform](https://img.shields.io/badge/platform-macOS%20(Apple%20Silicon%20%26%20Intel)-000?logo=apple)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![deps](https://img.shields.io/badge/dependencies-none-success)
![bilingual](https://img.shields.io/badge/i18n-EN%20%2F%20PL-orange)

One project, zero dependencies. **All scans are read-only** — they change nothing and need no `sudo`. Run it, get a score, and let `--fix` harden the machine for you (with your confirmation).

---

## ✨ Features

- 🖥️ **Native macOS app** — SwiftUI menu-bar app showing the score at a glance, with a native dashboard, `Scan` / `Fix` / `Report` buttons, a **score-trend sparkline**, **Start-at-login** and **Web-protection** toggles, an app icon, and a PL/EN switch. Built with `swiftc` only (no full Xcode needed).
- 🌐 **Web protection** — one switch installs a maintained blocklist (80k+ malware / phishing / tracker domains) into `/etc/hosts`, blocking bad sites system-wide. Fully reversible.
- 📥 **Downloads scanning** — flags unsigned installers, scripts, and extension-masquerade malware in `~/Downloads`.
- 🔐 **Zero-trust checks** — least-privilege account, TCC permission audit, and don't-trust-downloads posture.
- ✅ **Tested & self-audited** — 39-test suite + a security self-audit (shellcheck, secret scan, dangerous-pattern check) run in CI.
- **53 checks** across **11 categories** (system, malware/persistence, browsers, performance/leaks, network, file integrity, downloads)
- **Security Score 0–100** with severity weights + per-category scores
- Visual **HTML dashboard** (gauge, category nav, OK/Warn/Fail/Info cards, remediation commands), light & dark
- **`--fix` auto-hardening** — enables firewall, stealth, Gatekeeper, disables guest, sets immediate lock… interactively or `--yes`
- **Bilingual EN / PL** (auto-detected, override with `--lang`)
- Native macOS **notification** with the result
- **JSON export** (`--json`) for CI/automation
- Double-clickable **`.command`** launcher for non-terminal users

## 🖥️ Native app (recommended)

Build the double-clickable menu-bar app (needs only Xcode Command Line Tools — `xcode-select --install`):

```bash
git clone https://github.com/lkolo-prez/secure-scan.git
cd secure-scan
./build-app.sh                    # or: ./make-dmg.sh  →  dist/SecureScan-<ver>.dmg
open dist/SecureScan.app          # a 🛡 shield with your score appears in the menu bar
cp -R dist/SecureScan.app /Applications/   # optional: install it
```

> Prefer a download? Grab **`SecureScan-<version>.dmg`** from the [latest release](https://github.com/lkolo-prez/secure-scan/releases/latest), open it, and drag the app to Applications.

The app bundles the scan engine and runs it via `--json`; the score, breakdown and remediation live in a native SwiftUI panel. `Fix` triggers the standard macOS admin-password prompt. First launch of an unsigned app: right-click → **Open** (or *System Settings → Privacy & Security → Open Anyway*).

> Currently built for **Apple Silicon (arm64)**. Set `MACOS_TARGET=x86_64-apple-macos14.0` to build for Intel.

## 🚀 CLI quick start

```bash
./secure-scan.sh                  # from the cloned repo
```

Or install the CLI to `~/.local/bin`:

```bash
curl -fsSL https://raw.githubusercontent.com/lkolo-prez/secure-scan/main/install.sh | bash
secure-scan
```

## 🧭 Usage

```
secure-scan                       # scan + HTML dashboard (opens browser)
secure-scan --fix                 # auto-harden (asks before each change)
secure-scan --fix --yes           # auto-harden, no prompts
secure-scan --protect             # enable web protection (block malicious domains)
secure-scan --unprotect           # disable web protection
secure-scan --protect-status      # show whether web protection is active
secure-scan --json                # JSON output (CI)
secure-scan --lang en|pl          # force language
secure-scan --only core,malware   # run selected modules only
secure-scan --no-open             # don't open the browser
secure-scan --no-notify           # no macOS notification
secure-scan --help | --version
```

Modules: `core`, `malware`, `browser`, `perf`, `network`, `files`, `downloads`.

Environment variables:

| Variable | Effect |
|---|---|
| `SECURE_SCAN_OUT` | Directory for `security-dashboard.html` (default: the script directory) |
| `SECURE_SCAN_BLOCKLIST_URL` | Blocklist used by `--protect` (default: [StevenBlack/hosts](https://github.com/StevenBlack/hosts)) |

## 🌐 Web protection (block malicious sites)

```bash
secure-scan --protect     # installs a maintained blocklist into /etc/hosts (needs admin)
secure-scan --unprotect   # removes it and restores /etc/hosts
```

It fetches a well-known, maintained hosts blocklist ([StevenBlack/hosts](https://github.com/StevenBlack/hosts) by default) (malware + phishing + trackers, ~80k domains) with a bundled offline fallback, and writes it into a clearly-marked, reversible block in `/etc/hosts`, then flushes DNS. The app exposes the same thing as a **Web protection** switch.

## 🔍 What it checks

| Category | Checks |
|---|---|
| 🔐 **Encryption & Boot** | FileVault, SIP, Secure Boot / Signed System Volume |
| 🌐 **Network & Firewall** | Application firewall, stealth mode, SSH, Screen Sharing (VNC), AirPlay Receiver |
| 🛡️ **Updates & Protection** | System updates, auto-updates, Gatekeeper, XProtect |
| 👤 **Accounts & Access** | Root, guest, automatic login, screen-lock password, login password hints, **least-privilege (zero-trust)** |
| 🔒 **Privacy & System** | Kernel extensions, system extensions, config profiles / MDM, **TCC permission audit** |
| 🧟 **Malware & Persistence** | Suspicious launch items (trojan patterns), cron jobs, known adware/PUP, ClamAV status, Downloads hygiene, **`/etc/hosts` redirect tampering** |
| 🌍 **Browsers** | Extension counts per browser, enforced policies (hijack signs), internet plug-ins |
| 🔥 **Performance & Leaks** | Top CPU, high-RSS processes (memory leaks), swap/memory pressure, uptime |
| 📡 **Network Activity** | External listening ports, outbound connections, VPN, DNS resolver, proxy/PAC, file-sharing exposure, firewall block-all, **web protection (domain blocking)** |
| 📁 **File Integrity** | SUID/SGID binaries, launch-dir permissions, quarantine flags, `/tmp` executables, Time Machine backups, SSH private keys |
| 📥 **Downloads & Scripts** | **Unsigned installers, scripts/executables in Downloads, extension-masquerade malware, quarantine hygiene** |

## 🔧 Auto-hardening (`--fix`)

`--fix` inspects each hardening item; if it's already secure it's skipped, otherwise you're asked before anything changes (or pass `--yes`):

```bash
secure-scan --fix          # interactive
secure-scan --fix --yes    # apply everything
```

Enables: firewall, stealth mode, Gatekeeper · disables: guest account, remote login (SSH) · sets: immediate screen lock. All reversible.

## 📊 Scoring

Each scored check has a **weight** by severity (FileVault/firewall = 10, AirPlay = 3). `WARN` earns half, `FAIL` earns zero, `INFO` items are advisory and don't affect the score.

| Score | Grade |
|---|---|
| 90–100 | Excellent |
| 75–89 | Good |
| 60–74 | Needs work |
| < 60 | Poor |

## 🤖 JSON / CI

```bash
secure-scan --json | jq '.score'
```

```json
{ "tool": "secure-scan", "version": "3.2.0", "score": 90, "grade": "Excellent",
  "pass": 31, "warn": 7, "fail": 0, "info": 15, "checks": [ … ] }
```

## 🧪 Development & testing

```bash
bash tests/run-tests.sh          # 39 unit/integration tests (no deps)
bash scripts/security-audit.sh   # self-audit: shellcheck, secret scan, dangerous patterns
```

CI runs both on every push, then builds `SecureScan.app` and the DMG on a macOS runner.

## 🗂️ Project layout

```
secure-scan/
├── secure-scan.sh          # engine orchestrator (args, i18n, render)
├── secure-scan.command     # double-clickable CLI launcher
├── build-app.sh            # builds the native SecureScan.app
├── make-dmg.sh             # packages the distributable DMG
├── app/Sources/SecureScan/
│   └── SecureScan.swift     # SwiftUI menu-bar frontend
├── tools/IconGen.swift      # renders the app icon
├── lib/
│   ├── core.sh             # framework: i18n, scoring, HTML/JSON, notify
│   ├── checks_core.sh      # system baseline (accounts, zero-trust, TCC…)
│   ├── checks_malware.sh   # malware & persistence, /etc/hosts tampering
│   ├── checks_browser.sh   # browser threats
│   ├── checks_perf.sh      # CPU/memory leaks
│   ├── checks_network.sh   # network activity + web-protection status
│   ├── checks_files.sh     # file integrity
│   ├── checks_downloads.sh # downloads & scripts scanning
│   ├── remediate.sh        # --fix auto-hardening
│   ├── protect.sh          # --protect web/domain blocking
│   └── blocklist-seed.txt  # offline fallback blocklist
├── tests/run-tests.sh       # test suite
├── scripts/security-audit.sh# security self-audit
├── install.sh
└── README.md / README.pl.md
```

**How the app works:** `SecureScan.app/Contents/Resources/engine/` bundles the shell engine; the Swift frontend runs `secure-scan.sh --json`, decodes it, and renders a native panel. No reimplementation, one source of truth.

## ⚠️ Disclaimer

Scans are **read-only** and modify nothing. `--fix` only runs the actions you approve. Results are a security-hygiene indicator, not a guarantee. Use at your own risk.

## 🤝 Contributing

PRs welcome — new checks, translations, fixes. Keep checks **read-only** and dependency-free; put remediation behind `--fix`.

## 📄 License

MIT © 2026 **Aircloud — Łukasz Kołodziej** — see [LICENSE](LICENSE). Open source; contributions welcome.

---

Built by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Security hardening and audits for teams: [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
