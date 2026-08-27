#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ensure_run_dirs

stop_one() {
  local service="$1"
  local pid_file="${PID_DIR}/${service}.pid"
  if [[ ! -f "${pid_file}" ]]; then
    echo "${service}: no pid file"
    return 0
  fi
  local pid
  pid="$(cat "${pid_file}")"
  if is_pid_running "${pid}"; then
    echo "Stopping ${service} (pid ${pid})"
    # Kill process group if possible (mvn + forked JVM).
    kill "${pid}" 2>/dev/null || true
    # Also try children via pkill on spring-boot:run / jar main (best-effort).
    sleep 1
    if is_pid_running "${pid}"; then
      kill -9 "${pid}" 2>/dev/null || true
    fi
  else
    echo "${service}: pid ${pid} not running"
  fi
  rm -f "${pid_file}"
}

# Stop gateway first, then backends.
for svc in edge payment order product customer; do
  stop_one "${svc}"
done

# Stop background stripe listen if we started it.
STRIPE_PID_FILE="${PID_DIR}/stripe-listen.pid"
if [[ -f "${STRIPE_PID_FILE}" ]]; then
  spid="$(cat "${STRIPE_PID_FILE}")"
  if is_pid_running "${spid}"; then
    echo "Stopping stripe listen (pid ${spid})"
    kill "${spid}" 2>/dev/null || true
    sleep 1
    if is_pid_running "${spid}"; then
      kill -9 "${spid}" 2>/dev/null || true
    fi
  fi
  rm -f "${STRIPE_PID_FILE}"
fi
pkill -f "stripe listen --forward-to" 2>/dev/null || true

# Best-effort: stop leftover Spring Boot JVMs started via this workspace mvnw.
pkill -f "${MSA_DIR}/.*spring-boot:run" 2>/dev/null || true

echo "App stop requested."
