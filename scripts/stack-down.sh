#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

stack_stop_failed=0
if ! bash "${SCRIPT_DIR}/apps-stop.sh"; then
  echo "Application shutdown encountered errors." >&2
  stack_stop_failed=1
fi
if ! bash "${SCRIPT_DIR}/infra-stop.sh"; then
  echo "Infrastructure shutdown encountered errors." >&2
  stack_stop_failed=1
fi
if (( stack_stop_failed != 0 )); then
  echo "Stack shutdown incomplete. Inspect the errors above and container states before restarting." >&2
  exit 1
fi
echo "Stack down (containers stopped; volumes kept). For wipe: make infra-reset"
