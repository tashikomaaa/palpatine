# backup.sh — plugin de sauvegarde impériale

plugin_backup_menu(){
  draw_header
  draw_section_title "$(L 'plugin.backup.title')"
  draw_line
  draw_menu_option "1" "🗄️" "$(L 'plugin.backup.option_etc')"
  draw_menu_option "2" "💾" "$(L 'plugin.backup.option_www')"
  draw_menu_option "3" "↩️" "$(L 'menu.back')"
  draw_line
  local prompt
  prompt=$'\e[94m'"$(L 'prompt.choice_short') "
  read -rp "${prompt}${COL_RESET}" sub
  case "$sub" in
    1)
      empire "$(L 'plugin.backup.log_etc')"
      for s in "${SERVERS[@]}"; do
        run_ssh_cmd "$s" "sudo tar czf /tmp/etc-$(date +%Y%m%d).tar.gz /etc"
      done
      ;;
    2)
      empire "$(L 'plugin.backup.log_www')"
      for s in "${SERVERS[@]}"; do
        run_ssh_cmd "$s" "sudo tar czf /tmp/www-$(date +%Y%m%d).tar.gz /var/www"
      done
      ;;
    3) : ;;  # retour = no-op, on laisse la main au menu principal
    *) alert "$(L 'alert.invalid')" ;;
  esac
}

register_plugin "backup" "$(L 'plugin.backup.label')" plugin_backup_menu
