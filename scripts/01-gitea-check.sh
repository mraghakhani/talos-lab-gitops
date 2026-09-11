#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd curl
require_env GITEA_HTTP_URL

log "checking Gitea API: $GITEA_HTTP_URL"
curl --fail --silent --show-error --max-time 5 \
  "$GITEA_HTTP_URL/api/v1/version"
echo
ok "Gitea is reachable from the laptop"
note "Argo CD pods will reach Gitea through ${GITEA_SSH_HOST:-192.168.231.1}, not localhost."
