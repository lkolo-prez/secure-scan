# 🛡️ secure-scan

> **Advanced macOS security auditor** — a native menu-bar **`.app`** (and CLI) that runs 46 read-only checks across 10 categories, shows a **Security Score (0–100)**, and offers **one-click auto-hardening**.

**🇬🇧 English** · [🇵🇱 Polski](README.pl.md)

[![CI](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml/badge.svg)](https://github.com/lkolo-prez/secure-scan/actions/workflows/ci.yml)
![shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)
![platform](https://img.shields.io/badge/platform-macOS%20(Apple%20Silicon%20%26%20Intel)-000?logo=apple)
![license](https://img.shields.io/badge/license-MIT-blue)
![deps](https://img.shields.io/badge/dependencies-none-success)
![bilingual](https://img.shields.io/badge/i18n-EN%20%2F%20PL-orange)

One project, zero dependencies. **All scans are read-only** — they change nothing and need no `sudo`. Run it, get a score, and let `--fix` harden the machine for you (with your confirmation).

---

## ✨ Features

- 🖥️ **Native macOS app** — SwiftUI menu-bar app showing the score at a glance, with a native dashboard, `Scan` / `Fix` / `Report` buttons and a PL/EN toggle. Built with `swiftc` only (no full Xcode needed).
- **46 checks** across **10 categories** (system, malware/persistence, browsers, performance/leaks, network, file integrity)
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
./build-app.sh
open dist/SecureScan.app          # a 🛡 shield with your score appears in the menu bar
cp -R dist/SecureScan.app /Applications/   # optional: install it
```

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
secure-scan --json                # JSON output (CI)
secure-scan --lang en|pl          # force language
secure-scan --only core,malware   # run selected modules only
secure-scan --no-open             # don't open the browser
secure-scan --help | --version
```

Modules: `core`, `malware`, `browser`, `perf`, `network`, `files`.

## 🔍 What it checks

| Category | Checks |
|---|---|
| 🔐 **Encryption & Boot** | FileVault, SIP, Secure Boot / Signed System Volume |
| 🌐 **Network & Firewall** | Application firewall, stealth mode, SSH, Screen Sharing (VNC), AirPlay Receiver |
| 🛡️ **Updates & Protection** | System updates, auto-updates, Gatekeeper, XProtect |
| 👤 **Accounts & Access** | Root, guest, automatic login, screen-lock password, login password hints |
| 🔒 **Privacy & System** | Kernel extensions, system extensions, config profiles / MDM |
| 🧟 **Malware & Persistence** | Suspicious launch items (trojan patterns), cron jobs, known adware/PUP, ClamAV status, Downloads hygiene, **`/etc/hosts` redirect tampering** |
| 🌍 **Browsers** | Extension counts per browser, enforced policies (hijack signs), internet plug-ins |
| 🔥 **Performance & Leaks** | Top CPU, high-RSS processes (memory leaks), swap/memory pressure, uptime |
| 📡 **Network Activity** | External listening ports, outbound connections, VPN, DNS resolver, **proxy/PAC**, **file-sharing exposure**, firewall block-all |
| 📁 **File Integrity** | SUID/SGID binaries, launch-dir permissions, quarantine flags, `/tmp` executables, **Time Machine backups**, **SSH private keys** |

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
{ "tool": "secure-scan", "version": "3.0.0", "score": 88, "grade": "Good",
  "pass": 27, "warn": 5, "fail": 0, "info": 14, "checks": [ … ] }
```

## 🗂️ Project layout

```
secure-scan/
├── secure-scan.sh          # engine orchestrator (args, i18n, render)
├── secure-scan.command     # double-clickable CLI launcher
├── build-app.sh            # builds the native SecureScan.app
├── app/Sources/SecureScan/
│   └── SecureScan.swift     # SwiftUI menu-bar frontend
├── lib/
│   ├── core.sh             # framework: i18n, scoring, HTML/JSON, notify
│   ├── checks_core.sh      # system baseline (5 categories)
│   ├── checks_malware.sh   # malware & persistence
│   ├── checks_browser.sh   # browser threats
│   ├── checks_perf.sh      # CPU/memory leaks
│   ├── checks_network.sh   # network activity
│   ├── checks_files.sh     # file integrity
│   └── remediate.sh        # --fix auto-hardening
├── install.sh
└── README.md / README.pl.md
```

**How the app works:** `SecureScan.app/Contents/Resources/engine/` bundles the shell engine; the Swift frontend runs `secure-scan.sh --json`, decodes it, and renders a native panel. No reimplementation, one source of truth.

## ⚠️ Disclaimer

Scans are **read-only** and modify nothing. `--fix` only runs the actions you approve. Results are a security-hygiene indicator, not a guarantee. Use at your own risk.

## 🤝 Contributing

PRs welcome — new checks, translations, fixes. Keep checks **read-only** and dependency-free; put remediation behind `--fix`.

## 📄 License

MIT © 2026 — see [LICENSE](LICENSE).
