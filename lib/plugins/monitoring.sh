#!/bin/bash
# Palapatine - Open Source Project
# Copyright (C) 2025  Moutarlier Aldwin aka (tashikomaaa or corvus)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
