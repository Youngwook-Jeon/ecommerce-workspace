#!/usr/bin/env bash
# Shared helpers for workspace run scripts.
set -euo pipefail

# This file lives at scripts/lib/common.sh — resolve workspace root from here
# (BASH_SOURCE[0] is this file when sourced, not the caller).
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "${LIB_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${SCRIPTS_DIR}/.." && pwd)"
MSA_DIR="${ROOT_DIR}/ecommerce-msa"
DOCKER_DIR="${MSA_DIR}/deployment/docker"
FRONTEND_DIR="${ROOT_DIR}/ecommerce-frontend"
RUN_DIR="${ROOT_DIR}/.run"
LOG_DIR="${RUN_DIR}/logs"
PID_DIR="${RUN_DIR}/pids"
ENV_FILE="${MSA_DIR}/.env"
ENV_EXAMPLE="${MSA_DIR}/.env.example"
MVNW="${MSA_DIR}/mvnw"

ensure_run_dirs() {
  mkdir -p "${LOG_DIR}" "${PID_DIR}"
}

load_msa_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    if [[ -f "${ENV_EXAMPLE}" ]]; then
      echo "Missing ${ENV_FILE}." >&2
      echo "Create it first:  cp ${ENV_EXAMPLE} ${ENV_FILE}" >&2
    else
      echo "Missing ${ENV_FILE} (and no .env.example)." >&2
    fi
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
}

require_cmd() {
  local name="$1"
  if ! command -v "${name}" >/dev/null 2>&1; then
    echo "Required command not found: ${name}" >&2
    exit 1
  fi
}

maven_module_for_service() {
  case "$1" in
    edge) echo "edge-service" ;;
    product) echo "product-service/product-service-main" ;;
    order) echo "order-service/order-service-main" ;;
    payment) echo "payment-service/payment-service-main" ;;
    customer) echo "customer-service" ;;
    *)
      echo "Unknown service: $1 (expected: edge|product|order|payment|customer)" >&2
      exit 1
      ;;
  esac
}

service_port() {
  case "$1" in
    edge) echo "9000" ;;
    product) echo "9002" ;;
    order) echo "9003" ;;
    payment) echo "9004" ;;
    customer) echo "9001" ;;
    *)
      echo "Unknown service: $1" >&2
      exit 1
      ;;
  esac
}

jar_glob_for_service() {
  case "$1" in
    edge) echo "${MSA_DIR}/edge-service/target/edge-service-*.jar" ;;
    product) echo "${MSA_DIR}/product-service/product-service-main/target/product-service-main-*.jar" ;;
    order) echo "${MSA_DIR}/order-service/order-service-main/target/order-service-main-*.jar" ;;
    payment) echo "${MSA_DIR}/payment-service/payment-service-main/target/payment-service-main-*.jar" ;;
    customer) echo "${MSA_DIR}/customer-service/target/customer-service-*.jar" ;;
    *)
      echo "Unknown service: $1" >&2
      exit 1
      ;;
  esac
}

resolve_boot_jar() {
  local service="$1"
  local pattern
  pattern="$(jar_glob_for_service "${service}")"
  # Prefer executable Spring Boot jar (exclude .jar.original).
  local jar
  jar="$(ls -1 ${pattern} 2>/dev/null | grep -v '\.jar\.original$' | head -n 1 || true)"
  if [[ -z "${jar}" || ! -f "${jar}" ]]; then
    echo "No packaged jar for ${service}. Run: make package" >&2
    exit 1
  fi
  echo "${jar}"
}

wait_http() {
  local url="$1"
  local label="$2"
  local attempts="${3:-60}"
  local i
  for ((i = 1; i <= attempts; i++)); do
    if curl -sf "${url}" >/dev/null 2>&1; then
      echo "${label} is up (${url})"
      return 0
    fi
    # Some actuators are missing; accept any TCP connect + HTTP response that is not connection-refused.
    if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "${url}" 2>/dev/null | grep -Eq '^[0-9]{3}$'; then
      echo "${label} is responding (${url})"
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for ${label} (${url})" >&2
  return 1
}

is_pid_running() {
  local pid="$1"
  [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null
}
