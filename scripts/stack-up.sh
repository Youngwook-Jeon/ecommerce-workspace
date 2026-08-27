#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

load_msa_env

bash "${SCRIPT_DIR}/infra-up.sh"
bash "${SCRIPT_DIR}/apps-build.sh"
bash "${SCRIPT_DIR}/apps-run.sh"
bash "${SCRIPT_DIR}/apps-wait.sh"
bash "${SCRIPT_DIR}/debezium-setup.sh"

cat <<EOF

Stack is up.
  Gateway:     http://localhost:9000
  Kafka UI:    http://localhost:9090
  Connect:     http://localhost:8083
  Keycloak:    http://localhost:8080

Frontend (optional):  make frontend

Stripe (optional): set in ecommerce-msa/.env
  PAYMENT_PROVIDER=stripe
  STRIPE_API_KEY=sk_test_...
  (STRIPE_WEBHOOK_SECRET is auto-fetched via stripe listen --print-secret;
   listen runs in the background — no manual paste / payment restart needed.)
  Then: make apps   or   make up

Logs: ${LOG_DIR}
EOF
