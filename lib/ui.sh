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

# Translation dictionaries are initialised lazily to keep startup cost low.
declare -gA _L_EN=()
declare -gA _L_FR=()
_L_INIT=0

_init_locales(){
  ((_L_INIT)) && return
  _L_INIT=1

  declare -gA _L_EN=(
    [app_name]="$APP_NAME"
    [tagline]="$TAGLINE"
    [quote]="\"Good... let the SSH flow through you.\""
    [cfg_active]="Active configuration:"
    [cfg_group]="Group"
    [cfg_user]="User"
    [cfg_jobs]="Loaded systems"
    [cfg_timeout]="Timeout"
    [menu.scan]="Scan systems (ping + uptime)"
    [menu.run]="Execute an order"
    [menu.reboot]="Reboot the fleet"
    [menu.shutdown]="Shutdown the fleet"
    [menu.focus]="Control a system (focus)"
    [menu.plugins]="Open the plugin bay"
    [menu.back]="Return"
    [menu.quit]="Quit the Empire"
    [prompt.choice]="Choice (or letter: s=scan, r=reboot, q=quit):"
    [prompt.choice_short]="Choice:"
    [prompt.enter]="[Press Enter to continue]"
    [prompt.confirm]="Confirm? Type Y to confirm:"
    [prompt.retry_interactive]="Retry interactively? [y/N]:"
    [prompt.password_q]="Password required for"
    [empire.scan]="Scanning the fleet..."
    [empire.deploy]="Deploying the order:"
    [empire.completed]="Scan finished."
    [status.ping_ok]="Ping: OK"
    [status.ping_fail]="Ping failed for"
    [focus.title]="Focus"
    [focus.status_label]="Status"
    [focus.status_online]="online"
    [focus.status_offline]="offline"
    [focus.menu.uptime]="Check uptime"
    [focus.menu.run]="Execute command"
    [focus.menu.reboot]="Reboot"
    [focus.menu.shutdown]="Shutdown"
    [focus.menu.ssh]="Open interactive SSH"
    [focus.menu.back]="Return to fleet"
    [focus.prompt.command]="Command to run:"
    [focus.prompt.select]="Num or hostname (e.g. 2 or root@web-01):"
    [plugins.title]="Plugin hangar"
    [plugins.prompt.choice]="Select a plugin (0 to return):"
    [plugins.none]="No plugins loaded."
    [plugin.backup.label]="Imperial backups"
    [plugin.backup.title]="📦 Imperial backup module"
    [plugin.backup.option_etc]="Backup /etc on all servers"
    [plugin.backup.option_www]="Backup /var/www on all servers"
    [plugin.backup.log_etc]="Backing up /etc"
    [plugin.backup.log_www]="Backing up /var/www"
    [plugin.monitoring.label]="Imperial monitoring"
    [plugin.monitoring.title]="🛰️ Imperial monitoring"
    [msg.no_servers]="No servers found."
    [alert.invalid]="Invalid choice."
    [alert.cancel]="Operation cancelled."
    [victory.farewell]="The Empire salutes you."
  )

  declare -gA _L_FR=(
    [quote]="« Que le SSH coule en vous. »"
    [menu.plugins]="Ouvrir le hangar à plugins"
    [menu.back]="Retour"
    [prompt.choice_short]="Choix :"
    [prompt.confirm]="Confirmer ? Tapez O pour valider :"
    [prompt.retry_interactive]="Réessayer en interactif ? [o/N]:"
    [focus.status_label]="Statut"
    [focus.status_online]="en ligne"
    [focus.status_offline]="hors ligne"
    [focus.menu.uptime]="Consulter l'uptime"
    [focus.menu.run]="Exécuter une commande"
    [focus.menu.reboot]="Redémarrer"
    [focus.menu.shutdown]="Éteindre"
    [focus.menu.ssh]="Ouvrir un SSH interactif"
    [focus.menu.back]="Retour à la flotte"
    [focus.prompt.command]="Commande à exécuter :"
    [focus.prompt.select]="Numéro ou hôte (ex. 2 ou root@web-01) :"
    [plugins.title]="Hangar à plugins"
    [plugins.prompt.choice]="Choisissez un plugin (0 pour revenir) :"
    [plugins.none]="Aucun plugin chargé."
    [plugin.backup.label]="Sauvegardes impériales"
    [plugin.backup.title]="📦 Module de sauvegarde impériale"
    [plugin.backup.option_etc]="Sauvegarder /etc sur tous les serveurs"
    [plugin.backup.option_www]="Sauvegarder /var/www sur tous les serveurs"
    [plugin.backup.log_etc]="Sauvegarde de /etc"
    [plugin.backup.log_www]="Sauvegarde de /var/www"
    [plugin.monitoring.label]="Monitoring impérial"
    [plugin.monitoring.title]="🛰️ Monitoring impérial"
  )
}

_locale_lookup(){
  _init_locales
  local key="$1"
  local lang="${UI_LANG,,}"
  local value=""

  case "$lang" in
    fr)
      value="${_L_FR[$key]:-}"
      [[ -n "$value" ]] || value="${_L_EN[$key]:-}"
      ;;
    en|*)
      value="${_L_EN[$key]:-}"
      ;;
  esac

  if [[ -z "$value" ]]; then
    printf '%s' "$key"
  else
    printf '%s' "$value"
  fi
}

# L(key) returns translated string according to UI_LANG
L(){
  local key="$1"
  _locale_lookup "$key"
  printf '\n'
}

_prompt_resolve_message(){
  local key="$1" fallback="$2"
  local message
  message="$(_locale_lookup "$key")"
  if [[ "$message" == "$key" && -n "$fallback" && "$fallback" != "$key" ]]; then
    message="$fallback"
  fi
  printf '%s' "$message"
}

_prompt_read(){
  local message="$1" __result="$2" color="$3" suffix="$4"
  local prompt input status
  printf -v prompt '%b%s%b%s' "$color" "$message" "$COL_RESET" "$suffix"
  IFS= read -r -p "$prompt" input
  status=$?
  printf -v "$__result" '%s' "$input"
  return $status
}

prompt_read_key(){
  local key="$1" __result="$2" fallback="${3:-$1}" color="${4:-$COL_INFO}" suffix="${5:- }"
  local message
  message="$(_prompt_resolve_message "$key" "$fallback")"
  _prompt_read "$message" "$__result" "$color" "$suffix"
}

prompt_read_text(){
  local message="$1" __result="$2" color="${3:-$COL_INFO}" suffix="${4:- }"
  _prompt_read "$message" "$__result" "$color" "$suffix"
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
