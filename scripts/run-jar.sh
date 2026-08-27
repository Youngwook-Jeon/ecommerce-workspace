#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SERVICE="${SERVICE:-}"
if [[ -z "${SERVICE}" ]]; then
  echo "Usage: SERVICE=payment make run-jar   (or: $0 <edge|product|order|payment|customer>)" >&2
  exit 1
fi

# Allow positional override: ./run-jar.sh payment
if [[ $# -ge 1 ]]; then
  SERVICE="$1"
fi

load_msa_env
jar="$(resolve_boot_jar "${SERVICE}")"
port="$(service_port "${SERVICE}")"

echo "Running ${SERVICE} from ${jar} (port ${port})"
exec java -jar "${jar}"
