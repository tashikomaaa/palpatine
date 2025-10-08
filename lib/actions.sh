#!/usr/bin/env bash
# lib/actions.sh
# Fleet actions: status (scan), run, reboot, shutdown.
# JSON export optional; interactive retry on auth failures is configurable.
# Comments in English.

# Read configuration variables from environment (set by main/config files)
# SCAN_OUTPUT_JSON: "true"/"false" (default true)
# SCAN_OUTPUT_DIR: directory for scans (optional)
# SCAN_OUTPUT_FILE: exact file path (optional, overrides DIR)
# SCAN_INTERACTIVE_RETRY: "true"/"false" - if true, offer to retry interactive auth per host during scan

SCAN_OUTPUT_JSON="${SCAN_OUTPUT_JSON:-true}"
SCAN_OUTPUT_DIR="${SCAN_OUTPUT_DIR:-}"
SCAN_OUTPUT_FILE="${SCAN_OUTPUT_FILE:-}"
SCAN_INTERACTIVE_RETRY="${SCAN_INTERACTIVE_RETRY:-false}"

# Ensure we have a LOG_DIR fallback
: "${LOG_DIR:=$BASE_DIR/logs}"
mkdir -p "$LOG_DIR"

# Simple JSON string escaper
_json_safe() {
    local s="${1:-}"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# ---------------------------
# action_status: scan the fleet, optionally produce JSON output
# ---------------------------
action_status(){
    summary_init
    empire "$(L 'empire.scan' 2>/dev/null || echo 'Scanning the fleet...')"
    
    # Determine if JSON should be generated
    local gen_json=false
    local scan_json_norm="${SCAN_OUTPUT_JSON,,}"
    if [[ -z "${SCAN_OUTPUT_JSON}" || "$scan_json_norm" == "true" ]]; then
        gen_json=true
    fi
    
    local scan_dir_default="${LOG_DIR}/scans"
    local scan_dir=""
    local scan_file=""
    
    if $gen_json; then
        if [[ -n "$SCAN_OUTPUT_FILE" ]]; then
            scan_file="$SCAN_OUTPUT_FILE"
            scan_dir="$(dirname "$scan_file")"
            mkdir -p "$scan_dir"
        else
            scan_dir="${SCAN_OUTPUT_DIR:-$scan_dir_default}"
            mkdir -p "$scan_dir"
            scan_file="$scan_dir/scan-$(date +%Y%m%d_%H%M%S).json"
        fi
        # start JSON array
        printf '%s\n' "[" > "$scan_file"
    fi
    
    # allow errors inside the loop without exiting the whole script
    set +e
    
    local first=true
    for s in "${SERVERS[@]}"; do
        draw_line
        printf ' 🛰️  System: %s\n' "$s"
        local hostpart="${s#*@}"
        local ping_stat="failed"
        local ssh_stat="not_attempted"
        local ssh_output=""
        local ssh_exit='null'
        
        # Ping
        if ping_host "$hostpart"; then
            ping_stat="ok"
            echo "   $(L 'status.ping_ok' 2>/dev/null || echo 'Ping: OK')"
            # Non-interactive SSH attempt for uptime
            ssh_exit=0
            ssh_output="$(ssh "${SSH_OPTS[@]}" "$(host_for "$s")" -- "uptime -p" 2>&1)" || ssh_exit=$?

            if (( ssh_exit == 0 )); then
                ssh_stat="ok"
            else
                if echo "$ssh_output" | grep -qiE "permission denied|authentication failed|no authentication methods available"; then
                    ssh_stat="auth_failed"
                    # If interactive retry is enabled and TTY present, offer interactive retry
                    if [[ -t 0 && "${SCAN_INTERACTIVE_RETRY,,}" == "true" ]]; then
                        local prompt ans
                        prompt=$'\e[94m'"$(L 'prompt.password_q' 2>/dev/null || echo 'Password required for') $s. $(L 'prompt.retry_interactive' 2>/dev/null || echo 'Retry interactively? [o/N]:') "
                        read -rp "${prompt}${COL_RESET}" ans || ans=""
                        if [[ "$ans" =~ ^[oOyY]$ ]]; then
                            # interactive retry using SSH_OPTS_INTERACTIVE
                            ssh_output="$(ssh "${SSH_OPTS_INTERACTIVE[@]}" "$(host_for "$s")" -- "uptime -p" 2>&1)" || ssh_exit=$?
                            if (( ssh_exit == 0 )); then
                                ssh_stat="ok"
                            elif echo "$ssh_output" | grep -qiE "permission denied|authentication failed|no authentication methods available"; then
                                ssh_stat="auth_failed"
                            elif [[ -z "${ssh_output//[$'\t\r\n ']/}" ]]; then
                                ssh_stat="failed_no_output"
                            else
                                ssh_stat="failed"
                            fi
                        fi
                    fi
                elif [[ -z "${ssh_output//[$'\t\r\n ']/}" ]]; then
                    ssh_stat="failed_no_output"
                else
                    ssh_stat="failed"
                fi
            fi
        else
            ping_stat="failed"
            echo "   $(L 'status.ping_fail' 2>/dev/null || echo 'Ping failed for') $s"
            ssh_stat="skipped"
        fi
        
        # Update the summary counters
        case "$ping_stat" in
            ok)
                if [[ "$ssh_stat" == "ok" ]]; then summary_update ok; else summary_update fail; fi
            ;;
            failed) summary_update down ;;
        esac
        
        # Write JSON object if required
        if $gen_json; then
            local maxlen=4000
            if [[ ${#ssh_output} -gt $maxlen ]]; then
                ssh_output="${ssh_output:0:$maxlen}\n...[truncated]"
            fi
            
            local j_host j_ping j_ssh j_output j_exit
            j_host=$(_json_safe "$s")
            j_ping=$(_json_safe "$ping_stat")
            j_ssh=$(_json_safe "$ssh_stat")
            j_output=$(_json_safe "$ssh_output")
            j_exit=$(_json_safe "${ssh_exit:-0}")

            if $first; then
                first=false
            else
                printf '%s\n' "," >> "$scan_file"
            fi

            {
                printf '  {\n' >> "$scan_file"
                printf '    "host": "%s",\n' "$j_host" >> "$scan_file"
                printf '    "ping": "%s",\n' "$j_ping" >> "$scan_file"
                printf '    "ssh": "%s",\n' "$j_ssh" >> "$scan_file"
                printf '    "ssh_output": "%s",\n' "$j_output" >> "$scan_file"
                printf '    "ssh_exit_code": %s,\n' "$j_exit" >> "$scan_file"
                printf '    "scanned_at": "%s"\n' "$(iso_timestamp)" >> "$scan_file"
                printf '  }\n' >> "$scan_file"
            }
        fi

    done
    
    # restore strict mode
    set -e
    
    if $gen_json; then
        printf '%s\n' "" >> "$scan_file"
        printf '%s\n' "]" >> "$scan_file"
        empire "$(L 'empire.completed' 2>/dev/null || echo 'Scan finished.') $scan_file"
    else
        empire "$(L 'empire.completed' 2>/dev/null || echo 'Scan finished.')"
    fi
    
    summary_print
}

# ---------------------------
# action_run_command: parallel command runner across fleet
# ---------------------------
action_run_command(){
    prompt_read_key 'focus.prompt.command' cmdline 'Order to run:' "$COL_INFO" || cmdline=""
    [[ -z "${cmdline:-}" ]] && { alert "$(L 'alert.cancel' 2>/dev/null || echo 'Operation cancelled.')"; return; }
    empire "$(L 'empire.deploy' 2>/dev/null || echo 'Deploying:') ${COL_MENU}$cmdline${COL_RESET}"
    summary_init
    set +e
    local pids=()
    for s in "${SERVERS[@]}"; do
        wait_for_slot pids
        (
            draw_line
            printf ' 🛰️  System: %s\n' "$s"
            if ping_host "${s#*@}"; then
                run_ssh_cmd "$s" "$cmdline" && summary_update ok || summary_update fail
            else
                failure "   $(L 'status.ping_fail' 2>/dev/null || echo 'Ping failed for') $s"
                summary_update down
            fi
        ) &
        pids+=($!)
    done
    wait "${pids[@]}" 2>/dev/null || true
    set -e
    summary_print
}

# ---------------------------
# action_reboot_or_shutdown: reboot or shutdown fleet (protected)
# ---------------------------
action_reboot_or_shutdown(){
    local op="$1"
    local verb prompt_text c
    
    # Choose human-readable verb (localized)
    if [[ "$op" == "reboot" ]]; then
        verb="$(L 'menu.reboot' 2>/dev/null || echo 'reboot the fleet')"
    else
        verb="$(L 'menu.shutdown' 2>/dev/null || echo 'shutdown the fleet')"
    fi
    
    # Build the confirmation prompt in a variable to avoid complex inline quoting
    prompt_text="$(L 'prompt.confirm' 2>/dev/null || echo 'Confirm? Type O to confirm:')"
    
    # Ask user for confirmation (colored). We put the coloring outside substitution to avoid quoting issues.
    local confirm_prompt
    confirm_prompt=$'\e[94m'"${prompt_text} "
    read -rp "${confirm_prompt}${COL_RESET}" c
    
    # If user didn't confirm, abort
    [[ "${c:-}" =~ ^([oO]|[yY])$ ]] || { alert "$(L 'alert.cancel' 2>/dev/null || echo 'Operation cancelled.')"; return; }
    
    empire "Order: $verb"
    summary_init
    
    # allow failures inside this operation without exiting the whole script
    set +e
    local pids=()
    
    for s in "${SERVERS[@]}"; do
        wait_for_slot pids
        (
            draw_line
            printf ' 🛰️  System: %s\n' "$s"
            if ping_host "${s#*@}"; then
                if [[ "$op" == "reboot" ]]; then
                    run_ssh_cmd "$s" "sudo /sbin/shutdown -r now" && summary_update ok || summary_update fail
                else
                    run_ssh_cmd "$s" "sudo /sbin/shutdown -h now" && summary_update ok || summary_update fail
                fi
            else
                failure "   $(L 'status.ping_fail' 2>/dev/null || echo 'Ping failed for') $s"
                summary_update down
            fi
        ) &
        pids+=($!)
    done
    
    # wait for all background jobs
    wait "${pids[@]}" 2>/dev/null || true
    
    # restore strict mode
    set -e
    
    summary_print
}

