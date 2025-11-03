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
mkdir -p "$LOG_DIR/audit"

# Audit logging configuration
AUDIT_LOG="${AUDIT_LOG:-$LOG_DIR/audit/palpatine-audit.log}"
ENABLE_AUDIT_LOG="${ENABLE_AUDIT_LOG:-true}"

# Default variables (can be overridden by config files)
GROUP="${GROUP:-default}"
SERVERS_FILE="${SERVERS_FILE:-$BASE_DIR/servers.txt}"
SSH_USER="${SSH_USER:-${USER:-root}}"
MAX_JOBS="${MAX_JOBS:-6}"
DRY_RUN="${DRY_RUN:-false}"
SSH_TIMEOUT="${SSH_TIMEOUT:-5}"

# Control whether scans offer interactive retry on auth failures
SCAN_INTERACTIVE_RETRY="${SCAN_INTERACTIVE_RETRY:-false}"

# Server tagging and filtering
# Set TAGS_FILTER to comma-separated tags to filter servers (e.g., "web,prod")
TAGS_FILTER="${TAGS_FILTER:-}"
declare -A SERVER_TAGS  # Associative array: server -> comma-separated tags

# SSH options: non-interactive first (BatchMode=yes)
SSH_OPTS=( -o BatchMode=yes -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=ask )
# SSH options for interactive attempts (allow password prompt)
SSH_OPTS_INTERACTIVE=( -o BatchMode=no -o "PreferredAuthentications=publickey,password" -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=ask )

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
  echo -e " [SUMMARY]"
  echo -e "   ${COL_OK}[OK]:${COL_RESET} $OK    ${COL_WARN}[ERR]:${COL_RESET} $FAIL    ${COL_ERR}[DOWN]:${COL_RESET} $DOWN"
  draw_line
  echo -e "  [LOG] $LOG_DIR"
}

# Pause helper
pause(){ read -rp $'\e[90m'"$(L 'prompt.enter' 2>/dev/null || echo '[Enter to continue]')"$'\e[0m' _ || true; }

# ----------------------------
# Audit logging
# ----------------------------
# Log command execution for auditing purposes
# Format: timestamp | user | hostname | action | target_servers | command | result
audit_log(){
  [[ "${ENABLE_AUDIT_LOG,,}" != "true" ]] && return 0

  local action="$1"
  local target="${2:-all}"
  local command="${3:-N/A}"
  local result="${4:-success}"

  local timestamp
  timestamp=$(iso_timestamp)
  local user="${USER:-unknown}"
  local hostname
  hostname=$(hostname 2>/dev/null || echo "unknown")

  # Sanitize command for logging (remove newlines, limit length)
  local cmd_sanitized
  cmd_sanitized=$(echo "$command" | tr '\n' ' ' | head -c 200)
  [[ ${#command} -gt 200 ]] && cmd_sanitized="${cmd_sanitized}..."

  # Log format: JSON-ish for easy parsing
  local log_entry
  log_entry=$(printf '{"timestamp":"%s","user":"%s","hostname":"%s","action":"%s","targets":"%s","command":"%s","result":"%s"}\n' \
    "$timestamp" "$user" "$hostname" "$action" "$target" "$cmd_sanitized" "$result")

  echo "$log_entry" >> "$AUDIT_LOG"
}

# Wrapper to audit SSH command execution
audit_ssh_cmd(){
  local target="$1"
  local cmd="$2"
  local result="${3:-unknown}"
  audit_log "ssh_command" "$target" "$cmd" "$result"
}

# ----------------------------
# Server management helpers
# ----------------------------

# Parse server entry and extract tags
# Format: user@host:port tags=tag1,tag2,tag3
# Returns: server_part (without tags)
parse_server_entry(){
  local entry="$1"
  local server_part tags_part

  # Extract tags if present
  if [[ "$entry" =~ ^([^[:space:]]+)[[:space:]]+tags=([^[:space:]]+) ]]; then
    server_part="${BASH_REMATCH[1]}"
    tags_part="${BASH_REMATCH[2]}"
    SERVER_TAGS["$server_part"]="$tags_part"
  else
    server_part="$entry"
    SERVER_TAGS["$server_part"]=""
  fi

  echo "$server_part"
}

# Check if server matches tag filter
# Returns 0 (true) if server matches, 1 (false) otherwise
server_matches_tags(){
  local server="$1"

  # No filter = all servers match
  [[ -z "$TAGS_FILTER" ]] && return 0

  local server_tags="${SERVER_TAGS[$server]:-}"

  # No tags on server = doesn't match if filter is set
  [[ -z "$server_tags" ]] && return 1

  # Check if any filter tag is in server tags
  IFS=',' read -ra filter_tags <<< "$TAGS_FILTER"
  IFS=',' read -ra srv_tags <<< "$server_tags"

  for ftag in "${filter_tags[@]}"; do
    for stag in "${srv_tags[@]}"; do
      [[ "$ftag" == "$stag" ]] && return 0
    done
  done

  return 1
}

load_servers(){
  local file
  file="$(current_servers_file)"
  SERVERS_FILE="$file"
  if [[ ! -f "$file" ]]; then
    failure "Servers file not found: $file"
    exit 2
  fi

  local raw_servers=()
  mapfile -t raw_servers < <(sed -e 's/#.*//' -e '/^\s*$/d' "$file")

  SERVERS=()
  for entry in "${raw_servers[@]}"; do
    local server
    server=$(parse_server_entry "$entry")

    # Apply tag filter if set
    if server_matches_tags "$server"; then
      SERVERS+=("$server")
    fi
  done

  if [[ ${#SERVERS[@]} -eq 0 ]]; then
    if [[ -n "$TAGS_FILTER" ]]; then
      failure "No servers found matching tags: $TAGS_FILTER"
    else
      failure "$(L 'msg.no_servers' 2>/dev/null || echo 'No servers found.')"
    fi
    exit 2
  fi

  # Display filter info if active
  if [[ -n "$TAGS_FILTER" ]]; then
    empire "Filtering servers with tags: $TAGS_FILTER (${#SERVERS[@]} matched)"
  fi
}

current_servers_file(){
  local file
  if [[ "${GROUP:-default}" != "default" ]]; then
    file="$BASE_DIR/servers-${GROUP}.txt"
  else
    file="${SERVERS_FILE:-$BASE_DIR/servers.txt}"
    if [[ "$file" != /* ]]; then
      file="$BASE_DIR/${file#./}"
    fi
  fi
  printf '%s\n' "$file"
}

add_server_entry(){
  local entry="$1"
  [[ -z "$entry" ]] && { alert "Empty server entry."; return 1; }
  local file
  file="$(current_servers_file)"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -Fxq "$entry" "$file"; then
    alert "Server already present: $entry"
    return 0
  fi
  printf '%s\n' "$entry" >> "$file"
  victory "Added $entry to $(basename "$file")"
}

remove_server_entry(){
  local entry="$1"
  [[ -z "$entry" ]] && { alert "Empty server entry."; return 1; }
  local file tmp
  file="$(current_servers_file)"
  if [[ ! -f "$file" ]]; then
    alert "Servers file not found: $file"
    return 1
  fi
  if ! grep -Fxq "$entry" "$file"; then
    alert "Server not found: $entry"
    return 1
  fi
  tmp="$(mktemp)"
  grep -Fxv "$entry" "$file" > "$tmp"
  mv "$tmp" "$file"
  victory "Removed $entry from $(basename "$file")"
}

host_for(){
  # Return user@host, extracting port if present
  # Format: user@host[:port]
  local target="$1"
  if [[ "$target" == *@* ]]; then
    echo "$target"
  else
    echo "${SSH_USER}@${target}"
  fi
}

# Extract port from target if specified (user@host:port)
# Returns port number or empty string
get_ssh_port(){
  local target="$1"
  if [[ "$target" =~ :([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# Get hostname without port (user@host:port -> user@host)
get_host_without_port(){
  local target="$1"
  echo "${target%%:*}"
}

# Build SSH command with port option if needed
build_ssh_opts(){
  local target="$1"
  local opts_var="$2"  # name of array variable to modify
  local port
  port=$(get_ssh_port "$target")

  # Copy array by reference
  local -n _opts="$opts_var"

  if [[ -n "$port" ]]; then
    _opts+=(-p "$port")
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
  local host; host="$(get_host_without_port "$(host_for "$target")")"

  # Build SSH options with port if specified
  local ssh_opts_batch=("${SSH_OPTS[@]}")
  local ssh_opts_interactive=("${SSH_OPTS_INTERACTIVE[@]}")
  build_ssh_opts "$target" ssh_opts_batch
  build_ssh_opts "$target" ssh_opts_interactive

  if [[ "$DRY_RUN" == "true" ]]; then
    empire "[DRY-RUN] ssh ${ssh_opts_batch[*]} $host -- $cmd"
    return 0
  fi

  # 1) Attempt non-interactive ssh first (capture output)
  local output rc
  output="$(ssh "${ssh_opts_batch[@]}" "$host" -- "$cmd" 2>&1)" || rc=$?
  rc=${rc:-0}

  if (( rc == 0 )); then
    # success: print output if present
    if [[ -n "$output" ]]; then
      echo "$output"
    fi
    audit_ssh_cmd "$target" "$cmd" "success"
    return 0
  fi

  # Inspect output to detect authentication failure
  if echo "$output" | grep -qiE "permission denied|authentication failed|no authentication methods available"; then
    # Authentication error
    if [[ -t 0 && "${SCAN_INTERACTIVE_RETRY,,}" == "true" ]]; then
      # prompt user to retry interactively for this host
      local prompt ans
      prompt=$'\e[94m'"$(L 'prompt.password_q' 2>/dev/null || echo 'Password required for') $host. $(L 'prompt.retry_interactive' 2>/dev/null || echo 'Retry interactively? [o/N]:') ${COL_RESET}"
      read -rp "${prompt}" ans || ans=""
      if [[ "$ans" =~ ^[oOyY]$ ]]; then
        # interactive retry using interactive SSH options
        local retry_rc=0
        ssh "${ssh_opts_interactive[@]}" "$host" -- "$cmd" || retry_rc=$?
        if (( retry_rc == 0 )); then
          audit_ssh_cmd "$target" "$cmd" "success_interactive"
        else
          audit_ssh_cmd "$target" "$cmd" "auth_failed"
        fi
        return $retry_rc
      else
        failure "Authentication failed for $host"
        echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
        audit_ssh_cmd "$target" "$cmd" "auth_failed"
        return $rc
      fi
    else
      # no TTY or interactive retry disabled
      failure "Authentication failed for $host"
      echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
      audit_ssh_cmd "$target" "$cmd" "auth_failed"
      return $rc
    fi
  fi

  # Other kinds of SSH error (network, dns, etc.)
  failure "SSH error for $host"
  echo "$output" | tee -a "$LOG_DIR/palpatine-errors.log"
  audit_ssh_cmd "$target" "$cmd" "ssh_error"
  return $rc
}

# Always open interactive ssh with interactive options (for manual sessions)
open_interactive_ssh(){
  local target="$1"
  local host; host="$(get_host_without_port "$(host_for "$target")")"

  # Build SSH options with port if specified
  local ssh_opts_interactive=("${SSH_OPTS_INTERACTIVE[@]}")
  build_ssh_opts "$target" ssh_opts_interactive

  if [[ "$DRY_RUN" == "true" ]]; then
    empire "[DRY-RUN] (interactive) ssh ${ssh_opts_interactive[*]} $host"
    return 0
  fi

  empire "Opening interactive SSH to $host (Ctrl+D or 'exit' to return)"
  ssh "${ssh_opts_interactive[@]}" "$host"
}
# Portable ISO-8601 timestamp helper (prefers GNU date, falls back to POSIX UTC)
iso_timestamp(){
  local ts
  if ts=$(date --iso-8601=seconds 2>/dev/null); then
    printf '%s\n' "$ts"
  else
    date -u "+%Y-%m-%dT%H:%M:%SZ"
  fi
}

# Cross-platform ping helper. Tries GNU-style timeout first, then falls back.
# Strips port if present (user@host:port -> extracts just hostname)
ping_host(){
  local target="$1"
  # Extract just the hostname/IP (remove user@ and :port)
  local hostname="${target##*@}"  # Remove user@ prefix
  hostname="${hostname%%:*}"       # Remove :port suffix

  if command -v timeout >/dev/null 2>&1; then
    if timeout 3 ping -c 1 "$hostname" &>/dev/null; then
      return 0
    fi
  fi

  if ping -c 1 -W 2 "$hostname" &>/dev/null; then
    return 0
  fi

  if ping -c 1 "$hostname" &>/dev/null; then
    return 0
  fi

  return 1
}
