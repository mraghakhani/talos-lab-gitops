#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

log()  { printf '==> %s\n' "$*"; }
ok()   { printf 'OK   %s\n' "$*"; }
note() { printf 'NOTE %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "required environment variable is missing: $name"
}

require_kubeconfig() {
  [[ -n "${KUBECONFIG:-}" ]] || die "KUBECONFIG is not set"
  [[ -s "$KUBECONFIG" ]] || die "KUBECONFIG does not exist or is empty: $KUBECONFIG"
}
