#!/usr/bin/env bash
# lib/core.sh
# Core helpers: logging, SSH wrappers, server loading, summary counters.
# Comments are in English for open-source.

# ----------------------------
# Defaults and safety wrappers
# ----------------------------
: "${BASE_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
: "${LOG_DIR:=$BASE_DIR/logs}"
mkdir -p "$LOG_DIR"

# Default variables (can be overridden by config files)
GROUP="${GROUP:-default}"
SERVERS_FILE="${SERVERS_FILE:-$BASE_DIR/servers.txt}"
SSH_USER="${SSH_USER:-${USER:-root}}"
MAX_JOBS="${MAX_JOBS:-6}"
DRY_RUN="${DRY_RUN:-false}"
SSH_TIMEOUT="${SSH_TIMEOUT:-5}"

# Control whether scans offer interactive retry on auth failures
SCAN_INTERACTIVE_RETRY="${SCAN_INTERACTIVE_RETRY:-false}"

# SSH options: non-interactive first (BatchMode=yes)
SSH_OPTS=( -o BatchMode=yes -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=ask )
# SSH options for interactive attempts (allow password prompt)
SSH_OPTS_INTERACTIVE=( -o BatchMode=no -o PreferredAuthentications=publickey,password -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=ask )

# ----------------------------
# Small UI/log helpers (rely on ui.sh for L and colors)
# ----------------------------
# empire(), victory(), alert(), failure(), draw_line(), draw_header are defined in ui.sh

# ----------------------------
# Summary counters
# ----------------------------
summary_init(){ OK=0; FAIL=0; DOWN=0; }
summary_update(){
  case "$1" in
    ok) ((OK++)) ;;
    fail) ((FAIL++)) ;;
    down) ((DOWN++)) ;;
  esac
}
summary_print(){
  draw_line
  echo -e " 🧾  $(L 'cfg_active' 2>/dev/null || echo 'Summary:')"
  echo -e "   ${COL_OK}✅ OK:${COL_RESET} $OK    ${COL_WARN}⚠️ Errors:${COL_RESET} $FAIL    ${COL_ERR}❌ Down:${COL_RESET} $DOWN"
  draw_line
  echo -e "  📜  Log: $LOG_DIR"
}

# Pause helper
pause(){ read -rp $'\e[90m'"$(L 'prompt.enter' 2>/dev/null || echo '[Enter to continue]')"$'\e[0m' _ || true; }

# ----------------------------
# Server management helpers
# ----------------------------
load_servers(){
  # Servers file may be overridden by GROUP variable: servers-<group>.txt
  if [[ "$GROUP" != "default" ]]; then
    SERVERS_FILE="$BASE_DIR/servers-$GROUP.txt"
  fi
  if [[ ! -f "$SERVERS_FILE" ]]; then
    failure "Servers file not found: $SERVERS_FILE"
    exit 2
  fi
  mapfile -t SERVERS < <(sed -e 's/#.*//' -e '/^\s*$/d' "$SERVERS_FILE")
  if [[ ${#SERVERS[@]} -eq 0 ]]; then
    failure "$(L 'msg.no_servers' 2>/dev/null || echo 'No servers found.')"
    exit 2
  fi
}

host_for(){
  # Return user@host if user is not embedded in target
  local target="$1"
  if [[ "$target" == *@* ]]; then
    echo "$target"
  else
    echo "${SSH_USER}@${target}"
  fi
}

# ----------------------------
# Concurrency helper: ensure max parallel jobs
# Usage: wait_for_slot pids_array_name
# ----------------------------
wait_for_slot(){
  local -n _pids=$1
  while :; do
    for i in "${!_pids[@]}"; do
      local pid=${_pids[$i]}
      if ! kill -0 "$pid" 2>/dev/null; then
        unset '_pids[i]'
      fi
    done
    ((${#_pids[@]} < MAX_JOBS)) && break
    sleep 0.15
  done
}

# ----------------------------
# SSH wrapper:
# - try non-interactive (BatchMode=yes) first
# - if it fails due to auth and interactive terminal is available and user consents,
#   retry interactively (this is controlled by SCAN_INTERACTIVE_RETRY for scans,
#   and interactive sessions always use interactive options).
# - DO NOT store passwords anywhere; user types them in the ssh prompt.
# ----------------------------
run_ssh_cmd(){
  local target="$1"; shift
  local cmd="$*"
  local host; host="$(host_for "$target")"

  if [[ "$DRY_RUN" == "true" ]]; then
    empire "[DRY-RUN] ssh ${SSH_OPTS[*]} $host -- $cmd"
    return 0
  fi

  # 1) Attempt non-interactive ssh first (capture output)
  local output rc
  output="$(ssh "${SSH_OPTS[@]}" "$host" -- "$cmd" 2>&1)" || rc=$?
  rc=${rc:-0}

  if (( rc == 0 )); then
    # success: print output if present
    if [[ -n "$output" ]]; then
      echo "$output"
    fi
    return 0
  fi

  # Inspect output to detect authentication failure
  if echo "$output" | grep -qiE "permission denied|authentication failed|no authentication methods available"; then
    # Authentication error
    if [[ -t 0 && "${SCAN_INTERACTIVE_RETRY,,}" == "true" ]]; then
      # prompt user to retry interactively for this host
      read -rp $'\e[94m'"$(L 'prompt.password_q' 2>/dev/null || echo 'Password required for') $host. $(L 'prompt.confirm' 2>/dev/null || echo 'Retry interactively? [o/N]:') "$COL_RESET ans
      if [[ "$ans" =~ ^[oO]$ ]]; then
        # interactive retry using interactive SSH options
        ssh "${SSH_OPTS_INTERACTIVE[@]}" "$host" -- "$cmd"
        return $?
      else
        failure "Authentication failed for $host"
        echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
        return $rc
      fi
    else
      # no TTY or interactive retry disabled
      failure "Authentication failed for $host"
      echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
      return $rc
    fi
  fi

  # Other kinds of SSH error (network, dns, etc.)
  failure "SSH error for $host"
  echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
  return $rc
}

# Always open interactive ssh with interactive options (for manual sessions)
open_interactive_ssh(){
  local target="$1"
  local host; host="$(host_for "$target")"

  if [[ "$DRY_RUN" == "true" ]]; then
    empire "[DRY-RUN] (interactive) ssh ${SSH_OPTS_INTERACTIVE[*]} $host"
    return 0
  fi

  empire "Opening interactive SSH to $host (Ctrl+D or 'exit' to return)"
  ssh "${SSH_OPTS_INTERACTIVE[@]}" "$host"
}
