#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

load_msa_env
ensure_run_dirs

# Inject CLI webhook secret + background stripe listen when using Stripe.
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ensure-stripe-local.sh"

start_one() {
  local service="$1"
  local module
  module="$(maven_module_for_service "${service}")"
  local pid_file="${PID_DIR}/${service}.pid"
  local log_file="${LOG_DIR}/${service}.log"

  if [[ -f "${pid_file}" ]]; then
    local existing
    existing="$(cat "${pid_file}")"
    if is_pid_running "${existing}"; then
      echo "${service} already running (pid ${existing})"
      return 0
    fi
    rm -f "${pid_file}"
  fi

  echo "Starting ${service} (${module}) → ${log_file}"
  (
    cd "${MSA_DIR}"
    nohup ./mvnw -pl "${module}" -am spring-boot:run \
      >"${log_file}" 2>&1 &
    echo $! >"${pid_file}"
  )
  echo "  pid $(cat "${pid_file}")"
}

# Boot order: backends first, gateway last.
start_one product
start_one order
start_one payment
start_one edge

echo "Apps starting. Logs: ${LOG_DIR}"
echo "Wait for health with: make apps-wait   (or included in make up)"
