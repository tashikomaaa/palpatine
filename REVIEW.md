# Palpatine – Code Review Notes

This audit highlights areas where the current Bash implementation could be strengthened.

## Critical issues

1. **Broken prompt composition in `run_ssh_cmd`**  
   The authentication retry prompt concatenates colored segments without closing the double quotes before the destination variable. The line currently expands to `read -rp <prompt> "$COL_RESET ans"`, so `read` interprets the literal `"$COL_RESET ans"` as a variable name with a space, which results in `read: bad variable name` and aborts the function. Recompose the prompt so that `$COL_RESET` is emitted separately and `ans` remains the variable name. 【F:lib/core.sh†L86-L101】

2. **Same quoting bug in the scan action**  
   The retry prompt in `action_status` repeats the exact quoting issue, which means the interactive retry path for scans fails with the same `read: bad variable name` error. Fixing the helper in `run_ssh_cmd` alone is insufficient; `action_status` needs the same adjustment. 【F:lib/actions.sh†L78-L105】

3. **Plugins never load**  
   Plugin scripts under `lib/plugins/` call `register_plugin`, but no loader defines that function or sources the directory. Because the main launcher only sources `lib/*.sh`, these plugins are effectively dead code. Introduce a plugin bootstrapper (e.g., source `lib/plugins/*.sh` and maintain a registry) and expose them through the interactive menu. 【F:palpatine†L27-L95】【F:lib/plugins/backup.sh†L1-L19】【F:lib/plugins/monitoring.sh†L1-L10】

## High-impact improvements

1. **Shell portability**  
   Several commands assume GNU userland. Examples: `ping -W` is unsupported on BSD/macOS, and `date --iso-8601=seconds` will fail on non-GNU systems. Consider detecting the platform or using portable fallbacks (e.g., `ping -c 1` plus `timeout`, or `date -u "+%Y-%m-%dT%H:%M:%SZ"`). 【F:lib/actions.sh†L78-L139】

2. **Internationalisation consistency**  
   While the main menu uses the `L()` helper, focus mode and plugins hard-code English or French text, so switching `UI_LANG` does not translate those menus. Routing their strings through `L()` (with keys defined in `ui.sh`) would keep the experience consistent. 【F:lib/focus.sh†L1-L59】【F:lib/plugins/backup.sh†L1-L19】【F:lib/plugins/monitoring.sh†L1-L10】

3. **Structured scan logging**  
   The JSON exporter truncates output to 4000 characters and adds manual commas/newlines. Using `jq` or `printf` with a here-doc template would make the file valid even if `ssh_output` contains embedded newlines or braces, and storing the command exit code would improve observability. 【F:lib/actions.sh†L118-L139】

## Quality-of-life suggestions

1. **Provide automated linting**  
   Adding a lightweight `shellcheck` job (even as a documentation command) would catch quoting bugs like the ones above before release.

2. **Document plugin architecture expectations**  
   Clarify in `README.md` how plugins should register themselves and how users enable them once the loader exists. This will encourage contributions and prevent drift between docs and behaviour. 【F:README.md†L1-L120】

3. **Test harness for safe dry-runs**  
   A small suite that exercises `--dry-run`, command parsing, and JSON generation against localhost would offer regression coverage without requiring live servers.

