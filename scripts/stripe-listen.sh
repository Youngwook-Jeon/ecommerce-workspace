#!/usr/bin/env bash
# Foreground stripe listen for debugging. Prefer make up / make apps when
# PAYMENT_PROVIDER=stripe — those auto-fetch whsec and start listen in background.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

FORWARD_URL="${STRIPE_FORWARD_URL:-http://localhost:9000/api/v1/payment_service/webhooks/stripe}"

if ! command -v stripe >/dev/null 2>&1; then
  echo "Stripe CLI not found. Install: https://stripe.com/docs/stripe-cli" >&2
  exit 1
fi

if [[ -f "${ENV_FILE}" ]]; then
  load_msa_env
fi

cat <<EOF
================================================================================
Foreground stripe listen (debug)

Normal flow (no manual whsec copy):
  1) ecommerce-msa/.env → PAYMENT_PROVIDER=stripe, STRIPE_API_KEY=sk_test_...
  2) make up   (or make apps)
     → stripe listen --print-secret → inject STRIPE_WEBHOOK_SECRET
     → background stripe listen → boot payment-service

This target only runs listen in the foreground for inspecting events.
================================================================================

EOF

if [[ -n "${STRIPE_API_KEY:-}" ]]; then
  exec stripe listen --forward-to "${FORWARD_URL}" --api-key "${STRIPE_API_KEY}"
fi

exec stripe listen --forward-to "${FORWARD_URL}"
