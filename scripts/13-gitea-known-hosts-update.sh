#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd ssh-keyscan
need_cmd ssh-keygen
need_cmd sort

require_env GITEA_SSH_HOST
require_env GITEA_SSH_PORT

out="$PROJECT_ROOT/config/gitea-known-hosts"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

log "scanning Gitea SSH host keys from ${GITEA_SSH_HOST}:${GITEA_SSH_PORT}"
ssh-keyscan \
  -p "$GITEA_SSH_PORT" \
  "$GITEA_SSH_HOST" 2>/dev/null \
  | sort -u >"$tmp"

[[ -s "$tmp" ]] || die "ssh-keyscan returned no Gitea host keys"

install -m 0644 "$tmp" "$out"

log "Gitea SSH host-key fingerprints"
ssh-keygen -lf "$out"

ok "wrote $out"
note "Host keys are public trust material, not secrets; commit this file to Git after verifying the fingerprints."
