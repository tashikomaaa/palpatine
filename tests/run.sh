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
cd "$BASE_DIR"

status=0
for test in tests/test_*.sh; do
  if ! bash "$test"; then
    status=1
  fi
done

if (( status == 0 )); then
  echo "All tests passed."
else
  echo "Tests failed." >&2
fi

exit $status
