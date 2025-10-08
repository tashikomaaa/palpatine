# AGENTS.md — Guidance for Codex-style Agents interacting with Palpatine

**Purpose:** this document explains how an external agent (for example: an AI coding assistant built with OpenAI Codex or similar) should interact with the *Palpatine* repository. It details the layout, available actions the agent can perform safely, file formats, conventions and clear rules to avoid destructive operations.

> All instructions are written in English and intended to make it easy to automate tasks like editing code, generating docs, producing configuration examples, or producing tests — while keeping safety constraints explicit.

---

## Table of contents

1. Scope & responsibilities for agents
2. Repository summary and important file paths
3. Safe operational rules (MUST read)
4. Available high-level actions for an agent
5. Data formats (scan JSON, audit log JSONL, servers files)
6. Example prompts / task templates for agents
7. Editing guidelines and commit message template
8. Debugging checklist and common errors
9. Appendix: quick reference of CLI options

---

## 1. Scope & responsibilities for agents

Agents interacting with this repository may be used to:

* produce or modify code (Bash files in `lib/`) and top-level `palpatine` script;
* produce documentation, README, example config files or LICENSE;
* produce tests, linters or helper scripts (e.g. `make`, `install.sh`);
* suggest or implement new features following the project's conventions.

Agents must NOT:

* execute remote SSH commands on real infrastructure without explicit, human-provided credentials and a deliberate confirmation step; in other words **never** run `ssh` or any destructive commands unless a human operator explicitly allows it and confirms context.
* write credentials, passwords, or private keys into the repository.
* change files outside the project scope without explicit instruction from a human maintainer.

Agents should favor **non-invasive edits**, provide clear diffs, and include tests/documentation for anything substantial.

---

## 2. Repo summary & important paths

```
palpatine/                # repo root
├── palpatine             # main launcher (executable Bash script)
└── lib/
    ├── core.sh          # core helpers, ssh wrapper, server loading
    ├── ui.sh            # UI + i18n helpers
    ├── actions.sh       # status/scan, run, reboot, shutdown
    └── focus.sh         # per-server interactive menu
~/.palpatine.conf        # optional per-user config (not in repo)
logs/                    # runtime logs and scan outputs
```

Key files an agent will edit most often:

* `palpatine` — entrypoint and CLI parsing
* `lib/actions.sh` — fleet actions logic
* `lib/core.sh` — ssh wrappers, audit helper
* `lib/ui.sh` — visual and i18n strings
* `lib/focus.sh` — per-server commands
* `README.md`, `AGENTS.md` — documentation

---

## 3. Safe operational rules (MUST read)

1. **Never run remote commands.** If the task requires running Palpatine against real servers, the agent must produce a patch or instructions and ask the user to run them.
2. **Prefer `DRY_RUN=true` for any generated invocation examples.** When generating CLI examples that would connect to hosts, annotate them with `--dry-run` or show how to set `DRY_RUN=true`.
3. **Avoid secrets in repo.** If the task looks like it needs credentials, instruct the human to use their own secure vault or environment variables outside the repo.
4. **Ask for clarification only when strictly necessary.** If the user's intent is ambiguous but a safe best-effort change can be produced, prefer producing a patch and clearly mark uncertain parts in comments.
5. **Produce tests or docstrings for substantial code changes.** Every non-trivial code modification should come with a short comment and a README update.
6. **Sanitize inputs** when generating shell code: avoid unquoted variable expansions in generated snippets unless deliberate and documented.

---

## 4. High-level actions for an agent

The agent can perform these actions when authorized:

* **Code edit**: produce a complete new file or a unified patch for an existing file. Always produce the full file content for `lib/*.sh` replacements.
* **Documentation**: write or update Markdown docs (`README.md`, `AGENTS.md`, `CONTRIBUTING.md`).
* **Feature implementation**: add a small feature (e.g. CLI flag), including code + doc updates + usage examples.
* **Lint / static-check advice**: suggest `shellcheck` fixes and provide corrected code.
* **Testing helpers**: produce a `tests/` directory with example shell invocations and expected outputs (where feasible).

**Important:** when performing code edits, the agent must produce a clear explanation and a concise patch (prefer full-file replacement for lib scripts).

---

## 5. Data formats

### Scan JSON (single-array file)

When `SCAN_OUTPUT_JSON=true`, scans are written as a single JSON array file like:

```json
[
  {
    "host": "root@192.168.1.10",
    "ping": "ok",
    "ssh": "ok",
    "ssh_output": "up 2 days, 3:05",
    "scanned_at": "2025-10-08T15:30:00+02:00"
  }
]
```

### Audit log (append-only JSON lines)

`logs/audit.log` contains one JSON object per line (JSONL):

```jsonl
{"time":"2025-10-08T15:30:00+02:00","user":"alice","action":"scan","targets":"host1,host2","cmd":"/path/to/scanfile","result":"OK:2,FAIL:0,DOWN:0"}
```

Agents generating log entries for tests should use the same compact schema.

### Servers file

Plain text, one host per line. Lines beginning with `#` are comments. Hosts can be `user@host` or plain `host` (default `SSH_USER` will be used).

Example:

```
# servers-prod.txt
root@192.168.1.10
web-01.example.com
```

---

## 6. Example prompts / task templates for Codex agents

Use these templates when asking an AI agent to modify or add functionality.

### A. Add a CLI flag

```
Task: Add a CLI flag `--scan-json` to the `palpatine` launcher that overrides config.
Files: palpatine, lib/actions.sh
Constraints: keep comments in English; ensure `bash -n` passes; do not execute any ssh.
Deliverable: full file contents for modified files and a short rationale.
```

### B. Implement audit_log only on non-dry-run actions

```
Task: Modify audit_log calls so the log entry is emitted only when DRY_RUN != true.
Files: lib/actions.sh, lib/core.sh
Constraints: keep changes minimal and include tests or example output lines.
```

### C. Add a new localized UI message

```
Task: Add a new key `menu.stats` to UI translations and use it in palpatine menu.
Files: lib/ui.sh, palpatine
Constraints: both `fr` and `en` translations must be present. Keep formatting consistent.
```

---

## 7. Editing guidelines and commit message template

* Use clear English comments when adding or changing code.
* Preserve `set -euo pipefail` at top-level scripts and wrap tolerant areas with `set +e` / `set -e`.
* Quote variables in expansions (e.g. `"$var"`) unless intentional.

**Suggested commit message format:**

```
feat: <short summary>

Longer description (why), files changed, and any migration notes.

Co-authored-by: CodexAgent <codex@example.com>
```

---

## 8. Debugging checklist & common errors

If shell errors occur, run these checks:

1. `bash -n file.sh` to syntax-check.
2. `dos2unix file.sh` to remove CRLF issues.
3. `shellcheck file.sh` for linting suggestions.
4. Verify `local` is used only inside functions.
5. Ensure all loops and conditionals (`for`, `if`, `case`) are properly closed with `done`, `fi`, `esac`.

Common runtime mistakes to avoid:

* Unescaped heredocs inside interpolated vars.
* Unmatched quotes when concatenating colored prompts.
* Using `read` without checking for TTY in non-interactive flows.

---

## 9. CLI quick reference

```
./palpatine [--group <name>] [--user <sshuser>] [--dry-run]
          [--action <status|run|reboot|shutdown>] [--cmd "<command>"]
          [--focus <server|index>] [--scan-json <true|false>]
          [--scan-file <path>] [--scan-dir <path>] [--ssh-bastion <user@bastion>]
          [--audit-log <true|false>]
```

---

If you want, I can also:

* produce a `CONTRIBUTING.md` that formalizes the code review process and CI checks,
* generate example unit test wrappers (using `bats` or simple shell test harness),
* or create a `PATCH_TEMPLATE.md` for PRs.

Which of these should I add next?
