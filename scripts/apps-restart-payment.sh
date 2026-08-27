#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

load_msa_env
ensure_run_dirs

# Refresh CLI secret + ensure listen is up before payment boots.
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ensure-stripe-local.sh"

SERVICE=payment
PID_FILE="${PID_DIR}/${SERVICE}.pid"
LOG_FILE="${LOG_DIR}/${SERVICE}.log"
MODULE="$(maven_module_for_service "${SERVICE}")"

if [[ -f "${PID_FILE}" ]]; then
  pid="$(cat "${PID_FILE}")"
  if is_pid_running "${pid}"; then
    echo "Stopping payment-service (pid ${pid})"
    kill "${pid}" 2>/dev/null || true
    sleep 2
    if is_pid_running "${pid}"; then
      kill -9 "${pid}" 2>/dev/null || true
    fi
  fi
  rm -f "${PID_FILE}"
fi

pkill -f "${MSA_DIR}/payment-service.*spring-boot:run" 2>/dev/null || true
sleep 1

echo "Starting payment-service (${MODULE}) → ${LOG_FILE}"
(
  cd "${MSA_DIR}"
  nohup ./mvnw -pl "${MODULE}" -am spring-boot:run \
    >"${LOG_FILE}" 2>&1 &
  echo $! >"${PID_FILE}"
)
echo "payment-service restarting (pid $(cat "${PID_FILE}"))"
