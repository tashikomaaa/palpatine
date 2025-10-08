#!/usr/bin/env bash
# install.sh - install Palpatine as a system-wide command

set -euo pipefail

usage(){
  cat <<USAGE
Usage: $0 [--prefix <path>] [--force]

Installs Palpatine into the specified prefix (default: /usr/local).
Copies the repository into <prefix>/share/palpatine and symlinks the
`palpatine` launcher into <prefix>/bin/palpatine.

Options:
  --prefix <path>  Installation prefix (default: /usr/local)
  --force          Overwrite an existing installation without prompting
  -h, --help       Show this help message
USAGE
}

PREFIX="/usr/local"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      PREFIX="$2"
      shift
      ;;
    --force)
      FORCE=true
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
INSTALL_ROOT="$PREFIX/share/palpatine"
BIN_DIR="$PREFIX/bin"
TARGET="$BIN_DIR/palpatine"

if [[ ! -d "$BIN_DIR" ]]; then
  echo "Creating $BIN_DIR" >&2
  mkdir -p "$BIN_DIR"
fi

if [[ -d "$INSTALL_ROOT" ]]; then
  if [[ "$FORCE" != true ]]; then
    echo "Existing installation detected in $INSTALL_ROOT" >&2
    echo "Re-run with --force to overwrite." >&2
    exit 1
  fi
  echo "Cleaning existing installation at $INSTALL_ROOT" >&2
  rm -rf "$INSTALL_ROOT"
fi

echo "Copying files to $INSTALL_ROOT" >&2
mkdir -p "$INSTALL_ROOT"

# Use rsync when available for efficient copying
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude '.git' \
    --exclude '.github' \
    --exclude 'logs' \
    "$SCRIPT_DIR/" "$INSTALL_ROOT/"
else
  (cd "$SCRIPT_DIR" && tar --exclude='.git' --exclude='.github' --exclude='logs' -cf - .) | (cd "$INSTALL_ROOT" && tar -xf -)
fi

chmod +x "$INSTALL_ROOT/palpatine"

if [[ -L "$TARGET" || -f "$TARGET" ]]; then
  if [[ "$FORCE" == true ]]; then
    rm -f "$TARGET"
  else
    echo "Binary already exists at $TARGET" >&2
    echo "Re-run with --force to replace the symlink." >&2
    exit 1
  fi
fi

echo "Linking $TARGET" >&2
ln -s "$INSTALL_ROOT/palpatine" "$TARGET"

cat <<SUMMARY
Palpatine installed successfully.
  Install root : $INSTALL_ROOT
  Binary link  : $TARGET

Add $PREFIX/bin to your PATH if it is not already.
SUMMARY
