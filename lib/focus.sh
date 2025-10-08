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
    draw_center "⚔️ $(L 'focus.title'): $server"
    draw_block_bot

    local status="offline"
    if ping_host "${server#*@}"; then
      status="online"
    fi

    # Print status line
    if [[ "$status" == "online" ]]; then
      echo -e " 🧭  $(L 'focus.status_label'): ${COL_OK}$(L 'focus.status_online')${COL_RESET}"
    else
      echo -e " 🧭  $(L 'focus.status_label'): ${COL_ERR}$(L 'focus.status_offline')${COL_RESET}"
    fi

    draw_line
    echo -e "${COL_MENU} 1) $(L 'focus.menu.uptime')${COL_RESET}"
    echo -e "${COL_MENU} 2) $(L 'focus.menu.run')${COL_RESET}"
    echo -e "${COL_MENU} 3) $(L 'focus.menu.reboot')${COL_RESET}"
    echo -e "${COL_MENU} 4) $(L 'focus.menu.shutdown')${COL_RESET}"
    echo -e "${COL_MENU} 5) $(L 'focus.menu.ssh')${COL_RESET}"
    echo -e "${COL_MENU} 6) $(L 'focus.menu.back')${COL_RESET}"
    draw_line

    local menu_prompt
    menu_prompt=$'\e[94m'"$(L 'prompt.choice_short' 2>/dev/null || echo 'Choice:') "
    read -rp "${menu_prompt}${COL_RESET}" sub

    case "${sub,,}" in
      1)
        if [[ "$status" == "online" ]]; then
          run_ssh_cmd "$server" "uptime -p"
        else
          failure "$(L 'status.ping_fail' 2>/dev/null || echo 'System offline.') $server"
        fi
        ;;
      2)
        local cmd_prompt
        cmd_prompt=$'\e[94m'"$(L 'focus.prompt.command' 2>/dev/null || echo 'Command to run:') "
        read -rp "${cmd_prompt}${COL_RESET}" cmd
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

  local pick_prompt
  pick_prompt=$'\e[94m'"$(L 'focus.prompt.select' 2>/dev/null || echo 'Num or hostname:') "
  read -rp "${pick_prompt}${COL_RESET}" pick
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
