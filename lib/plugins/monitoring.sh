plugin_monitoring_menu(){
  draw_header
  draw_block_top; draw_center "🛰️ Monitoring Impérial"; draw_block_bot
  for s in "${SERVERS[@]}"; do
    draw_line; echo " 📡 $s"
    run_ssh_cmd "$s" "uptime && df -h / && free -m | grep Mem"
  done
}

register_plugin "monitoring" "Monitoring Impérial" plugin_monitoring_menu
