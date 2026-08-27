#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

bash "${SCRIPT_DIR}/apps-stop.sh" || true
bash "${SCRIPT_DIR}/infra-stop.sh" || true
echo "Stack down (containers stopped; volumes kept). For wipe: make infra-reset"
