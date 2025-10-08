plugin_monitoring_menu(){
  draw_header
  draw_block_top
  draw_center "$(L 'plugin.monitoring.title')"
  draw_block_bot
  for s in "${SERVERS[@]}"; do
    draw_line
    echo " 📡 $s"
    run_ssh_cmd "$s" "uptime && df -h / && free -m | grep Mem"
  done
}

register_plugin "monitoring" "$(L 'plugin.monitoring.label')" plugin_monitoring_menu
