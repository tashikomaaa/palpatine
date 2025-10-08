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
