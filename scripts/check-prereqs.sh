#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd docker
require_cmd curl

missing=()
command -v kcat >/dev/null 2>&1 || missing+=(kcat)
command -v jq >/dev/null 2>&1 || missing+=(jq)
command -v nc >/dev/null 2>&1 || missing+=(nc)
command -v java >/dev/null 2>&1 || missing+=(java)

if [[ ! -x "${MVNW}" ]]; then
  echo "Maven wrapper missing or not executable: ${MVNW}" >&2
  exit 1
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing recommended tools: ${missing[*]}" >&2
  echo "kcat/nc are required by deployment/docker/startup.sh; jq by setup-debezium.sh." >&2
  exit 1
fi

echo "Prerequisites OK (docker, java, kcat, jq, nc, mvnw)."
