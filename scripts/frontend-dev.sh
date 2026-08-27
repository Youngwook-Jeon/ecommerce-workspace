#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

if [[ ! -d "${FRONTEND_DIR}" ]]; then
  echo "Frontend dir not found: ${FRONTEND_DIR}" >&2
  exit 1
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "bun not found. Install from https://bun.sh" >&2
  exit 1
fi

cd "${FRONTEND_DIR}"
bun install
exec bun run dev
