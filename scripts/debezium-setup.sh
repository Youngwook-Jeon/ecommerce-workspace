#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd curl
require_cmd jq

if ! curl -sf http://localhost:8083/connectors >/dev/null 2>&1; then
  echo "Kafka Connect is not reachable at http://localhost:8083" >&2
  echo "Run: make infra-up" >&2
  exit 1
fi

cd "${DOCKER_DIR}"
if ! bash ./scripts/setup-debezium.sh; then
  echo >&2
  echo "Debezium setup failed. Common causes:" >&2
  echo "  - product/order/payment Flyway not applied yet (apps must be healthy first)" >&2
  echo "  - Connect scripting libs empty (make infra-up runs prepare-connect-scripting-libs.sh)" >&2
  echo "  - Connector /status race after create (re-run: make debezium)" >&2
  echo "See: ecommerce-msa/deployment/docker/DEBEZIUM.md" >&2
  echo "List connectors: curl -s http://localhost:8083/connectors | jq ." >&2
  exit 1
fi
