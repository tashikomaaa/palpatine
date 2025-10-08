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

# Color palette
COL_RESET="\e[0m"
COL_HEADER="\e[91m"      # red
COL_SUB="\e[90m"         # dim gray
COL_INFO="\e[96m"        # cyan
COL_OK="\e[1;32m"        # green
COL_WARN="\e[1;33m"      # yellow
COL_ERR="\e[1;31m"       # red bold
COL_MENU="\e[1;37m"      # bold white

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
        menu.back) echo "Retour" ;;
        menu.quit) echo "Quit the Empire" ;;
        prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
        prompt.choice_short) echo "Choix :" ;;
        prompt.enter) echo "[Press Enter to continue]" ;;
        prompt.confirm) echo "Confirm? Type O to confirm:" ;;
        prompt.retry_interactive) echo "Réessayer en interactif ? [o/N]:" ;;
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
        menu.back) echo "Return" ;;
        menu.quit) echo "Quit the Empire" ;;
        prompt.choice) echo "Choice (or letter: s=scan, r=reboot, q=quit):" ;;
        prompt.choice_short) echo "Choice:" ;;
        prompt.enter) echo "[Press Enter to continue]" ;;
        prompt.confirm) echo "Confirm? Type Y to confirm:" ;;
        prompt.retry_interactive) echo "Retry interactively? [y/N]:" ;;
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
draw_line(){ echo -e "${COL_SUB}----------------------------------------------${COL_RESET}"; }
draw_block_top(){ echo -e "${COL_HEADER}╔══════════════════════════════════════════════════════════╗${COL_RESET}"; }
draw_block_bot(){ echo -e "${COL_HEADER}╚══════════════════════════════════════════════════════════╝${COL_RESET}"; }
draw_center(){ printf "%b║ %-54s ║%b\n" "$COL_HEADER" "$1" "$COL_RESET"; }

# Header that shows active configuration snapshot
draw_header(){
  clear
  if command -v figlet &>/dev/null; then
    # if figlet available, show stylized name (not strictly required)
    figlet -f slant "$(L 'app_name')" 2>/dev/null || echo -e "${COL_HEADER}$(L 'app_name')${COL_RESET}"
    echo -e "${COL_INFO}$(L 'tagline')  ${VERSION}${COL_RESET}"
  else
    draw_block_top
    draw_center "⚡ $(L 'app_name') — $(L 'tagline') ⚡    ${VERSION}"
    draw_block_bot
  fi
  echo -e "$(L 'quote')\n"
  echo -e "${COL_SUB}$(L 'cfg_active')${COL_RESET}"
  echo -e "   $(L 'cfg_group'): ${COL_MENU}${GROUP}${COL_RESET}   $(L 'cfg_user'): ${COL_MENU}${SSH_USER}${COL_RESET}   $(L 'cfg_jobs'): ${COL_MENU}${MAX_JOBS}${COL_RESET}   $(L 'cfg_timeout'): ${COL_MENU}${SSH_TIMEOUT}s${COL_RESET}"
  draw_line
}

# Branded logging wrappers
empire(){ echo -e "${COL_INFO}[$(L 'app_name')]${COL_RESET} $*"; }
victory(){ echo -e "${COL_OK}[✓]${COL_RESET} $*"; }
alert(){ echo -e "${COL_WARN}[!]${COL_RESET} $*"; }
failure(){ echo -e "${COL_ERR}[✖]${COL_RESET} $*"; }
