#!/usr/bin/env bash
# lib/focus.sh
# Focus / per-server interactive menu.
# Comments are in English for open-source readability.

# focus_server: enter an interactive sub-menu for a single server.
# Requires helpers from core/ui: run_ssh_cmd(), open_interactive_ssh(), draw_header(), draw_block_top(),
# draw_block_bot(), draw_line(), L(), pause(), failure(), alert(), COL_* variables, host_for().
focus_server(){
  local server="$1"
  while :; do
    draw_header
    draw_block_top
    draw_center "⚔️ Focus: $server"
    draw_block_bot

    local status="offline"
    if ping -c 1 -W 2 "${server#*@}" &>/dev/null; then
      status="online"
    fi

    # Print status line
    if [[ "$status" == "online" ]]; then
      echo -e " 🧭  Status: ${COL_OK}online${COL_RESET}"
    else
      echo -e " 🧭  Status: ${COL_ERR}offline${COL_RESET}"
    fi

    draw_line
    echo -e "${COL_MENU} 1) uptime${COL_RESET}"
    echo -e "${COL_MENU} 2) execute command${COL_RESET}"
    echo -e "${COL_MENU} 3) reboot${COL_RESET}"
    echo -e "${COL_MENU} 4) shutdown${COL_RESET}"
    echo -e "${COL_MENU} 5) open interactive SSH${COL_RESET}"
    echo -e "${COL_MENU} 6) return to fleet${COL_RESET}"
    draw_line

    read -rp $'\e[94m'"$(L 'prompt.choice' 2>/dev/null || echo 'Choice:') "'$COL_RESET' sub

    case "${sub,,}" in
      1)
        if [[ "$status" == "online" ]]; then
          run_ssh_cmd "$server" "uptime -p"
        else
          failure "$(L 'status.ping_fail' 2>/dev/null || echo 'System offline.') $server"
        fi
        ;;
      2)
        read -rp $'\e[94m'"Command to run: "'$COL_RESET' cmd
        if [[ -n "${cmd:-}" ]]; then
          run_ssh_cmd "$server" "$cmd"
        else
          alert "$(L 'alert.cancel' 2>/dev/null || echo 'Cancelled')"
        fi
        ;;
      3)
        run_ssh_cmd "$server" "sudo /sbin/shutdown -r now"
        ;;
      4)
        run_ssh_cmd "$server" "sudo /sbin/shutdown -h now"
        ;;
      5)
        open_interactive_ssh "$server"
        ;;
      6)
        break
        ;;
      *)
        alert "$(L 'alert.invalid' 2>/dev/null || echo 'Invalid choice.')"
        ;;
    esac

    pause
  done
}

# select_server: present the list of servers and let user pick by number or hostname.
select_server(){
  draw_line
  echo " ⚙️  Systems available:"
  local i=1
  for s in "${SERVERS[@]}"; do
    echo "  [$i] $s"
    ((i++))
  done
  draw_line

  read -rp $'\e[94m'"Num or hostname (e.g. 2 or root@web-01): "'$COL_RESET' pick
  if [[ -z "${pick:-}" ]]; then
    alert "$(L 'alert.cancel' 2>/dev/null || echo 'Cancelled')"
    return
  fi

  if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#SERVERS[@]} )); then
    focus_server "${SERVERS[$((pick-1))]}"
  else
    focus_server "$pick"
  fi
}
