#!/usr/bin/env bash
# lib/ui.sh
# UI helpers and simple i18n (L function).
# All comments in English.

# Application identity
APP_NAME="${APP_NAME:-PALPATINE}"
TAGLINE="${TAGLINE:-Galactic Server Control}"
VERSION="${VERSION:-v6}"

# Language (UI_LANG) may be set via config; default to 'fr' for historical reasons
UI_LANG="${UI_LANG:-fr}"

# Color palette (favor a modern pink/blue theme with strong contrast)
COL_RESET=$'\e[0m'
COL_HEADER=$'\e[38;5;213m'   # magenta accent
COL_SUB=$'\e[38;5;244m'      # muted grey
COL_INFO=$'\e[38;5;81m'      # cyan/blue accent
COL_OK=$'\e[1;32m'           # green
COL_WARN=$'\e[1;33m'         # yellow
COL_ERR=$'\e[1;31m'          # red bold
COL_MENU=$'\e[1;97m'         # bold white
COL_FRAME=$'\e[38;5;111m'    # frame/border color
COL_MUTED=$'\e[38;5;240m'    # divider color

# ----------------------------
# Layout helpers
# ----------------------------
_TERM_MIN_WIDTH=48

get_term_width(){
  local cols
  if cols=$(tput cols 2>/dev/null); then
    if (( cols < _TERM_MIN_WIDTH )); then
      echo "$_TERM_MIN_WIDTH"
    else
      echo "$cols"
    fi
  else
    echo 72
  fi
}

strip_ansi(){
  printf '%s' "$*" | sed -E $'s/\x1B\[[0-9;]*[A-Za-z]//g'
}

repeat_char(){
  local char="$1" count="$2" line
  if (( count <= 0 )); then
    printf ''
    return
  fi
  printf -v line '%*s' "$count" ''
  printf '%s' "${line// /$char}"
}

pad_line(){
  local text="$1" width="${2:-$(get_term_width)}"
  local plain
  plain="$(strip_ansi "$text")"
  local len=${#plain}
  if (( len >= width )); then
    echo "$text"
  else
    printf '%s%s' "$text" "$(repeat_char ' ' $((width - len)))"
  fi
}

# L(key) returns translated string according to UI_LANG
L(){
  local key="$1"
  case "${UI_LANG,,}" in
    fr)
      case "$key" in
        app_name) echo "$APP_NAME" ;;
        tagline) echo "$TAGLINE" ;;
        quote) echo "« Que le SSH coule en vous. »" ;;
        cfg_active) echo "Active configuration:" ;;
        cfg_group) echo "Group" ;;
        cfg_user) echo "User" ;;
        cfg_jobs) echo "Loaded systems" ;;
        cfg_timeout) echo "Timeout" ;;
        menu.scan) echo "Scan systems (ping + uptime)" ;;
        menu.run) echo "Execute an order" ;;
        menu.reboot) echo "Reboot the fleet" ;;
        menu.shutdown) echo "Shutdown the fleet" ;;
        menu.focus) echo "Control a system (focus)" ;;
        menu.plugins) echo "Ouvrir le hangar à plugins" ;;
        menu.add_server) echo "Ajouter un serveur" ;;
        menu.remove_server) echo "Supprimer un serveur" ;;
        menu.back) echo "Retour" ;;
        menu.quit) echo "Quit the Empire" ;;
        prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
        prompt.choice_short) echo "Choix :" ;;
        prompt.enter) echo "[Press Enter to continue]" ;;
        prompt.confirm) echo "Confirm? Type O to confirm:" ;;
        prompt.retry_interactive) echo "Réessayer en interactif ? [o/N]:" ;;
        prompt.add_server) echo "Serveur à ajouter (user@hôte) :" ;;
        prompt.remove_server) echo "Serveur à supprimer (numéro ou hôte) :" ;;
        prompt.password_q) echo "Password required for" ;;
        empire.scan) echo "Scanning the fleet..." ;;
        empire.deploy) echo "Deploying the order:" ;;
        empire.completed) echo "Scan finished." ;;
        status.ping_ok) echo "Ping: OK" ;;
        status.ping_fail) echo "Ping failed for" ;;
        focus.title) echo "Focus" ;;
        focus.status_label) echo "Statut" ;;
        focus.status_online) echo "en ligne" ;;
        focus.status_offline) echo "hors ligne" ;;
        focus.menu.uptime) echo "Consulter l'uptime" ;;
        focus.menu.run) echo "Exécuter une commande" ;;
        focus.menu.reboot) echo "Redémarrer" ;;
        focus.menu.shutdown) echo "Éteindre" ;;
        focus.menu.ssh) echo "Ouvrir un SSH interactif" ;;
        focus.menu.back) echo "Retour à la flotte" ;;
        focus.prompt.command) echo "Commande à exécuter :" ;;
        focus.prompt.select) echo "Numéro ou hôte (ex. 2 ou root@web-01) :" ;;
        plugins.title) echo "Hangar à plugins" ;;
        plugins.prompt.choice) echo "Choisissez un plugin (0 pour revenir) :" ;;
        plugins.none) echo "Aucun plugin chargé." ;;
        plugin.backup.label) echo "Sauvegardes impériales" ;;
        plugin.backup.title) echo "📦 Module de sauvegarde impériale" ;;
        plugin.backup.option_etc) echo "Sauvegarder /etc sur tous les serveurs" ;;
        plugin.backup.option_www) echo "Sauvegarder /var/www sur tous les serveurs" ;;
        plugin.backup.log_etc) echo "Sauvegarde de /etc" ;;
        plugin.backup.log_www) echo "Sauvegarde de /var/www" ;;
        plugin.monitoring.label) echo "Monitoring impérial" ;;
        plugin.monitoring.title) echo "🛰️ Monitoring impérial" ;;
        msg.no_servers) echo "No servers found." ;;
        alert.invalid) echo "Invalid choice." ;;
        alert.cancel) echo "Operation cancelled." ;;
        victory.farewell) echo "The Empire salutes you." ;;
        *) echo "$key" ;; # fallback prints key
      esac
      ;;
    en)
      case "$key" in
        app_name) echo "$APP_NAME" ;;
        tagline) echo "$TAGLINE" ;;
        quote) echo "\"Good... let the SSH flow through you.\"" ;;
        cfg_active) echo "Active configuration:" ;;
        cfg_group) echo "Group" ;;
        cfg_user) echo "User" ;;
        cfg_jobs) echo "Loaded systems" ;;
        cfg_timeout) echo "Timeout" ;;
        menu.scan) echo "Scan systems (ping + uptime)" ;;
        menu.run) echo "Execute an order" ;;
        menu.reboot) echo "Reboot the fleet" ;;
        menu.shutdown) echo "Shutdown the fleet" ;;
        menu.focus) echo "Control a system (focus)" ;;
        menu.plugins) echo "Open the plugin bay" ;;
        menu.add_server) echo "Add a server" ;;
        menu.remove_server) echo "Remove a server" ;;
        menu.back) echo "Return" ;;
        menu.quit) echo "Quit the Empire" ;;
        prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
        prompt.choice_short) echo "Choice:" ;;
        prompt.enter) echo "[Press Enter to continue]" ;;
        prompt.confirm) echo "Confirm? Type Y to confirm:" ;;
        prompt.retry_interactive) echo "Retry interactively? [y/N]:" ;;
        prompt.add_server) echo "Server to add (user@host):" ;;
        prompt.remove_server) echo "Server to remove (number or host):" ;;
        prompt.password_q) echo "Password required for" ;;
        empire.scan) echo "Scanning the fleet..." ;;
        empire.deploy) echo "Deploying the order:" ;;
        empire.completed) echo "Scan finished." ;;
        status.ping_ok) echo "Ping: OK" ;;
        status.ping_fail) echo "Ping failed for" ;;
        focus.title) echo "Focus" ;;
        focus.status_label) echo "Status" ;;
        focus.status_online) echo "online" ;;
        focus.status_offline) echo "offline" ;;
        focus.menu.uptime) echo "Check uptime" ;;
        focus.menu.run) echo "Execute command" ;;
        focus.menu.reboot) echo "Reboot" ;;
        focus.menu.shutdown) echo "Shutdown" ;;
        focus.menu.ssh) echo "Open interactive SSH" ;;
        focus.menu.back) echo "Return to fleet" ;;
        focus.prompt.command) echo "Command to run:" ;;
        focus.prompt.select) echo "Num or hostname (e.g. 2 or root@web-01):" ;;
        plugins.title) echo "Plugin hangar" ;;
        plugins.prompt.choice) echo "Select a plugin (0 to return):" ;;
        plugins.none) echo "No plugins loaded." ;;
        plugin.backup.label) echo "Imperial backups" ;;
        plugin.backup.title) echo "📦 Imperial backup module" ;;
        plugin.backup.option_etc) echo "Backup /etc on all servers" ;;
        plugin.backup.option_www) echo "Backup /var/www on all servers" ;;
        plugin.backup.log_etc) echo "Backing up /etc" ;;
        plugin.backup.log_www) echo "Backing up /var/www" ;;
        plugin.monitoring.label) echo "Imperial monitoring" ;;
        plugin.monitoring.title) echo "🛰️ Imperial monitoring" ;;
        msg.no_servers) echo "No servers found." ;;
        alert.invalid) echo "Invalid choice." ;;
        alert.cancel) echo "Operation cancelled." ;;
        victory.farewell) echo "The Empire salutes you." ;;
        *) echo "$key" ;;
      esac
      ;;
    *)
      # fallback to English
      case "$key" in
        *) echo "$key" ;;
      esac
      ;;
  esac
}

# UI drawing helpers
draw_line(){
  local width
  width=$(get_term_width)
  printf "%b%s%b\n" "$COL_MUTED" "$(repeat_char '─' "$width")" "$COL_RESET"
}

draw_block_top(){
  local width
  width=$(get_term_width)
  printf "%b╭%s╮%b\n" "$COL_FRAME" "$(repeat_char '─' $((width-2)))" "$COL_RESET"
}

draw_block_bot(){
  local width
  width=$(get_term_width)
  printf "%b╰%s╯%b\n" "$COL_FRAME" "$(repeat_char '─' $((width-2)))" "$COL_RESET"
}

draw_center(){
  local text="$1" width inner padding remaining plain
  width=$(get_term_width)
  inner=$((width-2))
  plain="$(strip_ansi "$text")"
  if (( ${#plain} > inner )); then
    text="${plain:0:inner}"
    plain="$text"
  fi
  padding=$(( (inner - ${#plain}) / 2 ))
  remaining=$(( inner - ${#plain} - padding ))
  printf "%b│%s%s%s│%b\n" \
    "$COL_FRAME" "$(repeat_char ' ' "$padding")" "$text" "$(repeat_char ' ' "$remaining")" "$COL_RESET"
}

draw_section_title(){
  local width
  width=$(get_term_width)
  printf "%b%s%b\n" "$COL_INFO" "$(pad_line " ✨ $1" "$width")" "$COL_RESET"
}

draw_menu_option(){
  local key="$1" icon="$2" label="$3" hint="${4:-}"
  printf " %b[%s]%b  %b%s %s%b" "$COL_INFO" "$key" "$COL_RESET" "$COL_MENU" "$icon" "$label" "$COL_RESET"
  if [[ -n "$hint" ]]; then
    printf " %b%s%b" "$COL_SUB" "$hint" "$COL_RESET"
  fi
  printf "\n"
}

draw_stat_row(){
  local label1="$1" value1="$2" label2="${3:-}" value2="${4:-}"
  local line=" ${label1} : ${value1}"
  if [[ -n "$label2" ]]; then
    line+="    ${label2} : ${value2}"
  fi
  echo -e "$line"
}

# Header that shows active configuration snapshot
draw_header(){
  clear
  local width border
  width=$(get_term_width)
  border="$(repeat_char '━' "$width")"
  printf "%b%s%b\n" "$COL_FRAME" "$border" "$COL_RESET"
  printf "%b%s%b\n" "$COL_HEADER" "$(pad_line " $(L 'app_name')  ${VERSION}" "$width")" "$COL_RESET"
  printf "%b%s%b\n" "$COL_INFO" "$(pad_line " $(L 'tagline')" "$width")" "$COL_RESET"
  printf "%b%s%b\n" "$COL_FRAME" "$border" "$COL_RESET"
  echo -e "${COL_SUB}$(L 'quote')${COL_RESET}\n"
  echo -e "${COL_SUB}$(L 'cfg_active')${COL_RESET}"

  local loaded=0
  if declare -p SERVERS >/dev/null 2>&1; then
    loaded=${#SERVERS[@]}
  fi

  draw_stat_row "🌌 $(L 'cfg_group')" "${COL_MENU}${GROUP}${COL_RESET}" \
                "👤 $(L 'cfg_user')" "${COL_MENU}${SSH_USER}${COL_RESET}"
  draw_stat_row "🛰️ $(L 'cfg_jobs')" "${COL_MENU}${loaded}${COL_RESET}" \
                "⏱️ $(L 'cfg_timeout')" "${COL_MENU}${SSH_TIMEOUT}s${COL_RESET}"
  draw_line
}

# Branded logging wrappers
empire(){ echo -e "${COL_INFO}[$(L 'app_name')]${COL_RESET} $*"; }
victory(){ echo -e "${COL_OK}[✓]${COL_RESET} $*"; }
alert(){ echo -e "${COL_WARN}[!]${COL_RESET} $*"; }
failure(){ echo -e "${COL_ERR}[✖]${COL_RESET} $*"; }
