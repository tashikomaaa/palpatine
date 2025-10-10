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
# install.sh - install Palpatine as a system-wide command with friendly prompts

set -euo pipefail

usage(){
  cat <<'USAGE'
Usage: ./install.sh [--prefix <path>] [--force] [--assume-yes]

Installs Palpatine so it can be launched globally. Copies the current
repository into <prefix>/share/palpatine (default: /usr/local/share/palpatine)
and creates/updates the launcher symlink at <prefix>/bin/palpatine.

Options:
  --prefix <path>   Installation prefix (default: /usr/local)
  --force           Overwrite an existing installation without prompting
  --assume-yes, -y  Skip interactive prompts (use defaults)
  -h, --help        Show this help message
USAGE
}

PREFIX="/usr/local"
FORCE=false
ASSUME_YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift
      ;;
    --force)
      FORCE=true
      ;;
    --assume-yes|--yes|-y)
      ASSUME_YES=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift

done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$ASSUME_YES" != true ]]; then
  read -rp "Installation prefix [$PREFIX]: " answer_prefix
  if [[ -n "${answer_prefix//[[:space:]]/}" ]]; then
    PREFIX="$answer_prefix"
  fi
fi

INSTALL_ROOT="$PREFIX/share/palpatine"
BIN_DIR="$PREFIX/bin"
TARGET="$BIN_DIR/palpatine"
SERVER_FILE="$INSTALL_ROOT/servers.txt"

progress(){
  local msg="$1"
  printf '\r[ .... ] %s' "$msg"
}

progress_done(){
  local msg="$1"
  printf '\r[ #### ] %s\n' "$msg"
}

confirm(){
  local prompt="$1"
  if [[ "$ASSUME_YES" == true ]]; then
    return 0
  fi
  read -rp "$prompt" reply
  [[ "$reply" =~ ^[yY]$ ]]
}

progress "Creating directories"
mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_ROOT"
progress_done "Directories ready"

if [[ -d "$INSTALL_ROOT" && -n $(ls -A "$INSTALL_ROOT" 2>/dev/null) ]]; then
  if [[ "$FORCE" != true ]]; then
    if ! confirm "Existing install detected at $INSTALL_ROOT. Overwrite? [y/N]: "; then
      echo "Aborting installation." >&2
      exit 1
    fi
  fi
  progress "Removing old installation"
  rm -rf "$INSTALL_ROOT"
  mkdir -p "$INSTALL_ROOT"
  progress_done "Old installation removed"
fi

progress "Copying files"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude '.git' \
    --exclude '.github' \
    --exclude 'logs' \
    "$SCRIPT_DIR/" "$INSTALL_ROOT/"
else
  (cd "$SCRIPT_DIR" && tar --exclude='.git' --exclude='.github' --exclude='logs' -cf - .) | (cd "$INSTALL_ROOT" && tar -xf -)
fi
progress_done "Files copied to $INSTALL_ROOT"

chmod +x "$INSTALL_ROOT/palpatine"

if [[ -L "$TARGET" || -f "$TARGET" ]]; then
  if [[ "$FORCE" != true && "$ASSUME_YES" != true ]]; then
    if ! confirm "A launcher already exists at $TARGET. Replace it? [y/N]: "; then
      echo "Launcher left untouched." >&2
      exit 1
    fi
  fi
  rm -f "$TARGET"
fi

progress "Linking launcher"
ln -s "$INSTALL_ROOT/palpatine" "$TARGET"
progress_done "Launcher linked at $TARGET"

if [[ ! -f "$SERVER_FILE" ]]; then
  cat <<'TEMPLATE' > "$SERVER_FILE"
# Palpatine servers list
# Add servers as one host per line, e.g.:
# root@192.168.1.10
TEMPLATE
fi

NEW_SERVER_ADDED=false
if [[ "$ASSUME_YES" != true ]]; then
  echo ""
  if confirm "Would you like to add a server to servers.txt now? [y/N]: "; then
    read -rp "Enter server (e.g. user@host): " server_entry
    if [[ -n "${server_entry//[[:space:]]/}" ]]; then
      printf '%s\n' "$server_entry" >> "$SERVER_FILE"
      NEW_SERVER_ADDED=true
    fi
  fi
fi

echo ""
cat <<SUMMARY
Palpatine installed successfully!
  Install root : $INSTALL_ROOT
  Binary link  : $TARGET
  Servers file : $SERVER_FILE
SUMMARY

if [[ "$NEW_SERVER_ADDED" == true ]]; then
  echo "Added your server entry to servers.txt."
fi

echo "Remember to keep $PREFIX/bin in your PATH."
