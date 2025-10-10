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

#!/usr/bin/env bash
# lib/plugins.sh
# Plugin registry and loader helpers.

# Arrays keyed by plugin ID
declare -ag PLUGIN_ORDER=()
declare -Ag PLUGIN_LABELS=()
declare -Ag PLUGIN_HANDLERS=()

register_plugin(){
  local id="$1" label="$2" handler="$3"

  if [[ -z "$id" || -z "$handler" ]]; then
    echo "register_plugin: id and handler are required" >&2
    return 1
  fi

  if [[ -n "${PLUGIN_HANDLERS[$id]:-}" ]]; then
    echo "register_plugin: plugin '$id' already registered" >&2
    return 1
  fi

  PLUGIN_ORDER+=("$id")
  PLUGIN_LABELS["$id"]="$label"
  PLUGIN_HANDLERS["$id"]="$handler"
}

load_plugins(){
  local plugin_dir="$LIB_DIR/plugins"
  [[ -d "$plugin_dir" ]] || return 0

  local file
  for file in "$plugin_dir"/*.sh; do
    [[ -e "$file" ]] || continue
    # shellcheck disable=SC1090
    source "$file"
  done
}

plugins_available(){
  ((${#PLUGIN_ORDER[@]} > 0))
}

show_plugin_menu(){
  if ! plugins_available; then
    alert "$(L 'plugins.none')"
    return
  fi

  while :; do
    draw_line
    echo -e "${COL_MENU}$(L 'plugins.title')${COL_RESET}"
    local idx=1
    local id
    for id in "${PLUGIN_ORDER[@]}"; do
      local label="${PLUGIN_LABELS[$id]}"
      echo -e " ${COL_MENU}$idx) ${label}${COL_RESET}"
      ((idx++))
    done
    echo -e " ${COL_MENU}0) $(L 'menu.back')${COL_RESET}"
    draw_line

    local choice
    local prompt
    prompt=$'\e[94m'"$(L 'plugins.prompt.choice') "
    read -rp "${prompt}${COL_RESET}" choice

    if [[ -z "${choice:-}" ]]; then
      alert "$(L 'alert.invalid')"
      continue
    fi

    if [[ "$choice" == "0" ]]; then
      break
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PLUGIN_ORDER[@]} )); then
      local plugin_id="${PLUGIN_ORDER[$((choice-1))]}"
      local handler="${PLUGIN_HANDLERS[$plugin_id]}"
      if declare -f "$handler" >/dev/null 2>&1; then
        "$handler"
      else
        failure "Plugin '$plugin_id' handler '$handler' missing"
      fi
    else
      alert "$(L 'alert.invalid')"
    fi
  done
}
