#!/usr/bin/env bash
# When PAYMENT_PROVIDER=stripe: fetch CLI whsec, start stripe listen in background,
# export STRIPE_WEBHOOK_SECRET for subsequent app processes.
#
# Must be *sourced* so the export is visible to the caller:
#   source "${SCRIPT_DIR}/ensure-stripe-local.sh"
set -euo pipefail

# When executed directly (not sourced), still resolve helpers.
if [[ -z "${LIB_DIR:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=lib/common.sh
  source "${SCRIPT_DIR}/lib/common.sh"
fi

FORWARD_URL="${STRIPE_FORWARD_URL:-http://localhost:9000/api/v1/payment_service/webhooks/stripe}"
STRIPE_PID_FILE="${PID_DIR}/stripe-listen.pid"
STRIPE_LOG_FILE="${LOG_DIR}/stripe-listen.log"
STRIPE_SECRET_FILE="${RUN_DIR}/stripe-webhook-secret"

ensure_run_dirs

if [[ "${PAYMENT_PROVIDER:-stub}" != "stripe" ]]; then
  echo "PAYMENT_PROVIDER=${PAYMENT_PROVIDER:-stub} — skipping Stripe CLI webhook setup."
  return 0 2>/dev/null || exit 0
fi

if ! command -v stripe >/dev/null 2>&1; then
  echo "PAYMENT_PROVIDER=stripe requires the Stripe CLI." >&2
  echo "Install: https://stripe.com/docs/stripe-cli" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -z "${STRIPE_API_KEY:-}" ]]; then
  echo "PAYMENT_PROVIDER=stripe requires STRIPE_API_KEY in ecommerce-msa/.env" >&2
  return 1 2>/dev/null || exit 1
fi

echo "Fetching Stripe CLI webhook signing secret (stripe listen --print-secret)..."
secret_raw="$(
  stripe listen --print-secret --api-key "${STRIPE_API_KEY}" 2>/dev/null \
    || stripe listen --print-secret 2>/dev/null \
    || true
)"
secret="$(printf '%s\n' "${secret_raw}" | tr -d '\r' | grep -Eo 'whsec_[A-Za-z0-9]+' | tail -n 1 || true)"

if [[ -z "${secret}" ]]; then
  echo "Failed to obtain whsec_ from Stripe CLI." >&2
  echo "Try: stripe login   then re-run." >&2
  return 1 2>/dev/null || exit 1
fi

printf '%s\n' "${secret}" >"${STRIPE_SECRET_FILE}"
export STRIPE_WEBHOOK_SECRET="${secret}"
echo "STRIPE_WEBHOOK_SECRET ready (injected into this shell; not required in .env)."

if [[ -f "${STRIPE_PID_FILE}" ]]; then
  existing="$(cat "${STRIPE_PID_FILE}")"
  if is_pid_running "${existing}"; then
    echo "stripe listen already running (pid ${existing})"
    return 0 2>/dev/null || exit 0
  fi
  rm -f "${STRIPE_PID_FILE}"
fi

echo "Starting stripe listen → ${FORWARD_URL}"
echo "  log: ${STRIPE_LOG_FILE}"
nohup stripe listen --forward-to "${FORWARD_URL}" --api-key "${STRIPE_API_KEY}" \
  >"${STRIPE_LOG_FILE}" 2>&1 &
echo $! >"${STRIPE_PID_FILE}"
echo "  pid $(cat "${STRIPE_PID_FILE}")"
