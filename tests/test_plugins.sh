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
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$BASE_DIR/lib"

# shellcheck disable=SC1090
source "$LIB_DIR/plugins.sh"

# Provide a minimal translation helper used by draw helpers if they surface.
L(){
  echo "$1"
}

fail(){
  echo "[FAIL] $*" >&2
  exit 1
}

assert_eq(){
  local expected="$1" actual="$2" message="$3"
  [[ "$expected" == "$actual" ]] || fail "$message (expected '$expected', got '$actual')"
}

# Reset registry to start clean.
reset_plugin_registry

register_plugin "demo" "Demo" "demo_handler"
assert_eq 1 "${#PLUGIN_ORDER[@]}" "register_plugin should store plugin order"
assert_eq "demo" "${PLUGIN_ORDER[0]}" "register_plugin should keep IDs"
[[ "${PLUGIN_LABELS[demo]}" == "Demo" ]] || fail "register_plugin should track labels"
[[ "${PLUGIN_HANDLERS[demo]}" == "demo_handler" ]] || fail "register_plugin should track handlers"

if register_plugin "demo" "Duplicate" "other" 2>/dev/null; then
  fail "register_plugin should reject duplicate IDs"
fi

plugins_available || fail "plugins_available should report true when plugins exist"

reset_plugin_registry
LIB_DIR="$BASE_DIR/lib"
load_plugins
(( ${#PLUGIN_ORDER[@]} >= 2 )) || fail "load_plugins should register bundled plugins"
for id in "${PLUGIN_ORDER[@]}"; do
  [[ -n "${PLUGIN_LABELS[$id]}" ]] || fail "Plugin $id missing label"
  [[ -n "${PLUGIN_HANDLERS[$id]}" ]] || fail "Plugin $id missing handler"
  declare -f "${PLUGIN_HANDLERS[$id]}" >/dev/null 2>&1 || fail "Plugin $id handler not defined"
done

echo "tests/test_plugins.sh ✓"
