#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Hit a cheap path; services may return 401/404 — connection is enough.
wait_http "http://localhost:9002/" "product-service" 90
wait_http "http://localhost:9003/" "order-service" 90
wait_http "http://localhost:9004/" "payment-service" 90
wait_http "http://localhost:9000/" "edge-service" 90

echo "All core services are responding."
