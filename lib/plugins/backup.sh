# backup.sh — plugin de sauvegarde impériale

plugin_backup_menu(){
  draw_header
  draw_block_top; draw_center "📦 Module de Sauvegarde Impériale"; draw_block_bot
  echo -e "${COL_MENU}1) Sauvegarder /etc sur tous les serveurs${COL_RESET}"
  echo -e "${COL_MENU}2) Sauvegarder /var/www sur tous les serveurs${COL_RESET}"
  echo -e "${COL_MENU}3) Retour${COL_RESET}"
  draw_line
  read -rp $'\e[94mChoix:\e[0m ' sub
  case "$sub" in
    1) empire "Sauvegarde de /etc"; for s in "${SERVERS[@]}"; do run_ssh_cmd "$s" "sudo tar czf /tmp/etc-$(date +%Y%m%d).tar.gz /etc"; done ;;
    2) empire "Sauvegarde de /var/www"; for s in "${SERVERS[@]}"; do run_ssh_cmd "$s" "sudo tar czf /tmp/www-$(date +%Y%m%d).tar.gz /var/www"; done ;;
    3) : ;;  # retour = no-op, on laisse la main au menu principal
    *) alert "Choix invalide." ;;
  esac
}

register_plugin "backup" "Sauvegardes impériales" plugin_backup_menu
