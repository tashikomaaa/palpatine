# PALPATINE — Galactic Server Control

**Version:** v6 (core-only)

Palpatine is a terminal-based fleet manager written in Bash. It provides a small, auditable, and extensible tool to run commands and manage services across many servers via SSH.

> Design goals: simple, auditable, minimal dependencies (ssh, coreutils), friendly for ops engineers and open-source collaboration.

---

## Table of contents

- [PALPATINE — Galactic Server Control](#palpatine--galactic-server-control)
  - [Table of contents](#table-of-contents)
  - [What is Palpatine?](#what-is-palpatine)
  - [Installation](#installation)
  - [Project layout](#project-layout)
  - [Quick start](#quick-start)
  - [Configuration](#configuration)
    - [Key variables explained](#key-variables-explained)
  - [Usage — CLI \& Interactive](#usage--cli--interactive)
    - [CLI mode (non-interactive)](#cli-mode-non-interactive)
    - [Interactive menu](#interactive-menu)
    - [Focus mode](#focus-mode)
    - [Plugins](#plugins)
  - [Scan JSON output format](#scan-json-output-format)
  - [Security \& best practices](#security--best-practices)
  - [Troubleshooting (common issues)](#troubleshooting-common-issues)
    - [`Permission denied (publickey,password)`](#permission-denied-publickeypassword)
    - [Script exits during scan (happens after first ping)](#script-exits-during-scan-happens-after-first-ping)
    - [`syntax error: unexpected end of file`](#syntax-error-unexpected-end-of-file)
    - [`local: can only be used in a function`](#local-can-only-be-used-in-a-function)
  - [Contributing](#contributing)
  - [Development notes (for maintainers)](#development-notes-for-maintainers)
  - [Example `~/.palpatine.conf` (copy/paste)](#example-palpatineconf-copypaste)
  - [License](#license)

---

## What is Palpatine?

Palpatine is a terminal-based fleet manager written in Bash. It provides:

* a TUI-like main menu for common fleet tasks (scan, run command, reboot, shutdown);
* a **focus mode** to control a single server interactively (run commands, SSH, reboot/shutdown);
* robust SSH handling: non-interactive first (good for automation), and optional interactive retry when a host requires a password;
* optional JSON scan output for integration with other tools;
* simple configuration via `/etc/palpatine.conf`, `~/.palpatine.conf`, or `./.palpatine.conf`;
* minimal i18n support (`UI_LANG=fr|en`).

Palpatine intentionally keeps dependencies tiny so it runs on most Linux and macOS hosts with `ssh` installed.

---

## Installation

Clone the repository and make the main script executable:

```bash
git clone https://github.com/tashikomaaa/palpatine.git palpatine
cd palpatine
chmod +x palpatine
```

Create your server list files in the repository root. By default Palpatine uses `servers.txt`. You can also use `servers-<group>.txt` and set `GROUP` in config.

Example `servers-prod.txt`:

```
root@192.168.1.10
admin@192.168.1.11
web-01.example.com
```

---

## Project layout

```
palpatine/                # repo root
├── palpatine             # main launcher (executable)
└── lib/
    ├── core.sh          # core helpers, SSH wrapper, server loading
    ├── ui.sh            # UI + i18n helpers
    ├── actions.sh       # status/scan, run, reboot, shutdown
    ├── focus.sh         # focus mode & server selection helpers
    ├── plugins.sh       # plugin registry + loader
    └── plugins/         # optional plugins (auto-loaded)
~/.palpatine.conf        # optional per-user config (not in repo)
```

All code is pure Bash and intended to be easy to inspect and modify.

---

## Quick start

1. Create or edit `~/.palpatine.conf` (see configuration section below).
2. Create your `servers.txt` or `servers-<group>.txt`.
3. Run:

```bash
./palpatine
```

Use the TUI menu to scan your fleet, run commands, or focus on an individual server.

You can also run non-interactive actions from CLI:

```bash
./palpatine --group prod --action status
./palpatine --action run --cmd "df -h"
./palpatine --focus "root@web-01"
./palpatine --action reboot --dry-run
```

---

## Configuration

Palpatine reads these config files (in order), where later files override earlier ones:

1. `/etc/palpatine.conf`
2. `~/.palpatine.conf`
3. `./.palpatine.conf` (project-local)

A sample `~/.palpatine.conf`:

```bash
# ~/.palpatine.conf
GROUP="prod"
SSH_USER="root"
MAX_JOBS=8
SSH_TIMEOUT=5
UI_LANG="fr"               # 'fr' or 'en'
THEME="empire"             # currently visual only
DRY_RUN=false

# Scan output options
SCAN_OUTPUT_JSON=true
SCAN_OUTPUT_DIR="$HOME/palpatine_scans"   # optional
SCAN_OUTPUT_FILE=""                       # optional (overrides DIR)

# If true, during scans Palpatine will offer to retry interactively per host when auth fails.
SCAN_INTERACTIVE_RETRY=true
```

### Key variables explained

* `GROUP` — default group name (uses `servers-<GROUP>.txt` if present).
* `SSH_USER` — default SSH username used for bare hostnames.
* `MAX_JOBS` — maximum parallel SSH jobs (concurrency).
* `SSH_TIMEOUT` — seconds for `ConnectTimeout` in SSH options.
* `UI_LANG` — UI language: `fr` or `en`.
* `DRY_RUN` — if `true`, no SSH commands will be executed (useful for testing).
* `SCAN_OUTPUT_JSON` — `true` / `false`; controls whether `action_status` writes JSON file.
* `SCAN_OUTPUT_DIR` — directory to write scan files (if not set, defaults to `./logs/scans`).
* `SCAN_OUTPUT_FILE` — exact file path for scan output (if set, overrides `SCAN_OUTPUT_DIR`).
* `SCAN_INTERACTIVE_RETRY` — if `true` and TTY present, when a host reports auth failure during scan, the user is prompted to retry interactively for that host.

---

## Usage — CLI & Interactive

### CLI mode (non-interactive)

Examples:

```bash
# show status (ping + attempt uptime)
./palpatine --group prod --action status

# run a command across the fleet
./palpatine --action run --cmd "df -h"

# reboot all servers (use --dry-run to test)
./palpatine --action reboot --dry-run

# open focus on server #2 from servers.txt
./palpatine --focus 2
```

### Interactive menu

Launch `./palpatine` without args. The main menu offers:

* Scan systems (ping + uptime)
* Execute an order (enter a command to run in parallel)
* Reboot the fleet
* Shutdown the fleet
* Focus on a server for per-host actions
* Open the plugin bay (if plugins are installed)

### Focus mode

Choose a server and you'll have options:

* `uptime` (runs `uptime -p`)
* run a custom command
* reboot / shutdown
* open an interactive SSH shell

### Plugins

Drop Bash scripts into `lib/plugins/` and call `register_plugin "id" "Label" handler_fn`. Palpatine loads them automatically at startup and surfaces them under the **Plugins** menu item. Each plugin receives access to the shared helpers (`run_ssh_cmd`, `draw_header`, translations via `L`, etc.), so you can build custom workflows without touching the core menu.

The repository ships with two examples:

* `backup.sh` — run fleet-wide `tar` backups of `/etc` or `/var/www`.
* `monitoring.sh` — stream uptime, disk, and memory stats across the fleet.

Document your plugin labels with `L 'plugin.<name>.label'` if you want multilingual support.

---

## Scan JSON output format

When `SCAN_OUTPUT_JSON=true`, scans are written to a file named:

* `${SCAN_OUTPUT_FILE}` (if set), otherwise
* `${SCAN_OUTPUT_DIR}/scan-YYYYMMDD_HHMMSS.json` (where the default `SCAN_OUTPUT_DIR` is `./logs/scans`).

Output is a single JSON array — each element is an object per host:

```json
[
  {
    "host": "root@192.168.1.10",
    "ping": "ok",
    "ssh": "ok",
    "ssh_output": "up 2 days,  3:05",
    "ssh_exit_code": 0,
    "scanned_at": "2025-10-08T15:30:00Z"
  }
]
```

Field meanings:

* `host`: the host string used (user@host or host).
* `ping`: `"ok"` or `"failed"`.
* `ssh`: one of `"ok"`, `"auth_failed"`, `"failed"`, `"failed_no_output"`, `"not_attempted"`, or `"skipped"`.
* `ssh_output`: captured stdout/stderr from `uptime -p` (truncated if long).
* `ssh_exit_code`: numeric exit status reported by the SSH command (`null` if the command was skipped).
* `scanned_at`: ISO-8601 timestamp of the scan for that host.

You can easily pipe the file into `jq` for queries:

```bash
jq '.[] | {host, ping, ssh}' logs/scans/scan-20251008_153000.json
```

---

## Security & best practices

* **Prefer SSH keys** (ed25519 or RSA). Use `ssh-keygen` and `ssh-copy-id` to install your public key on servers.
* `DRY_RUN=true` is useful to test the script without making changes.
* Palpatine uses `ssh -o BatchMode=yes` by default for non-interactive actions — this avoids blocking when running in automation/cron.
* If `SCAN_INTERACTIVE_RETRY=true`, Palpatine may prompt for passwords interactively **only if run in a TTY** — it will never store passwords.
* File permissions: keep `~/.ssh` permissions strict (`700` for `.ssh`, `600` for `authorized_keys`).
* Avoid running Palpatine as `root` on your workstation — prefer a normal user with SSH keys.

---

## Troubleshooting (common issues)

### `Permission denied (publickey,password)`

* You attempted SSH without a key available on server.
* Quick checks:

  * `ssh -vvv user@host` — inspect auth methods attempted.
  * Ensure `~/.ssh/id_ed25519` (or `id_rsa`) exists.
  * Use `ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host`.

### Script exits during scan (happens after first ping)

* This is usually `set -e` behavior interacting with failing commands.
* Palpatine wraps scan loops with `set +e` / `set -e` to avoid that; if you modified files and see early exit, ensure those guards exist.
* Run `bash -n lib/actions.sh` (and other lib files) to syntax-check script files.

### `syntax error: unexpected end of file`

* Often caused by:

  * a truncated file (transfer interrupted),
  * missing `fi`, `done`, or `}` in a function,
  * CRLF (Windows) line endings.
* Fixes:

  * Ensure the file is complete — `wc -l lib/actions.sh`.
  * Convert line endings: `dos2unix lib/actions.sh` or `sed -i 's/\r$//' lib/actions.sh`.
  * Run `bash -n lib/actions.sh` to pinpoint syntax errors.

### `local: can only be used in a function`

* `local` must appear only inside functions. Check you haven't used `local` at top-level.

---

## Contributing

Palpatine aims to be simple and auditable. If you want to contribute:

1. Fork the repo.
2. Add a clear commit message and provide tests or manual test steps.
3. Open a PR with explanation and rationale.

Suggested improvements:

* plugin system (planned)
* better i18n with locale files
* optional output formats: CSV, JSONL, Prometheus metrics
* richer interactive UI (fzf integration or `dialog`)

---

## Development notes (for maintainers)

* All code is intentionally plain Bash (POSIX-ish with Bashisms).
* Keep comments and variable names English for wide collaboration.
* Use `bash -n` for syntax checks and `shellcheck` when possible.
* Keep `set -euo pipefail` at top-level but wrap tolerant sections with `set +e` / `set -e`.

---

## Example `~/.palpatine.conf` (copy/paste)

```bash
# ~/.palpatine.conf - Palpatine configuration
GROUP="prod"
SSH_USER="deploy"
MAX_JOBS=8
SSH_TIMEOUT=5
UI_LANG="en"
DRY_RUN=false

SCAN_OUTPUT_JSON=true
SCAN_OUTPUT_DIR="$HOME/palpatine_scans"
SCAN_OUTPUT_FILE=""
SCAN_INTERACTIVE_RETRY=true
```

---

## License

Recommended: **MIT License** (simple and permissive). Create a `LICENSE` file with the MIT text and your name.

```
MIT License

Copyright (c) 2025 tashikomaaa

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

---
