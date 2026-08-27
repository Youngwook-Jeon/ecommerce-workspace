#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

bash "${SCRIPT_DIR}/check-prereqs.sh"
cd "${DOCKER_DIR}"
exec bash ./startup.sh
