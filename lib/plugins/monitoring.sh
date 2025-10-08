plugin_monitoring_menu(){
  draw_header
  draw_section_title "$(L 'plugin.monitoring.title')"
  for s in "${SERVERS[@]}"; do
    draw_line
    echo " 📡 $s"
    run_ssh_cmd "$s" "uptime && df -h / && free -m | grep Mem"
  done
}

register_plugin "monitoring" "$(L 'plugin.monitoring.label')" plugin_monitoring_menu
