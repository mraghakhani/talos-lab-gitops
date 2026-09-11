#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd git
need_cmd ssh
need_cmd ssh-keygen

for var in GITEA_SSH_HOST GITEA_SSH_PORT GITOPS_REPO_URL; do
  require_env "$var"
done

key="$PROJECT_ROOT/.secrets/gitea-argocd"
pub="$key.pub"

[[ -s "$key" ]] || die "deploy private key missing; run task gitea:keygen"
[[ -s "$pub" ]] || die "deploy public key missing; run task gitea:keygen"

log "deploy-key fingerprint"
ssh-keygen -lf "$pub"

log "testing raw SSH authentication to ${GITEA_SSH_HOST}:${GITEA_SSH_PORT}"
set +e
ssh_output="$(
  ssh \
    -i "$key" \
    -p "$GITEA_SSH_PORT" \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=accept-new \
    "git@$GITEA_SSH_HOST" 2>&1
)"
ssh_rc=$?
set -e

printf '%s\n' "$ssh_output"

# Gitea commonly closes an authenticated `ssh -T` session with a non-zero exit
# status after printing its successful-authentication banner, so the definitive
# repository test is `git ls-remote` below.
if ((ssh_rc != 0)); then
  note "raw ssh exited $ssh_rc; continuing to definitive git ls-remote check"
fi

log "testing read-only Git access to $GITOPS_REPO_URL"
GIT_SSH_COMMAND="ssh -i '$key' -p '$GITEA_SSH_PORT' -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new" \
  git ls-remote "$GITOPS_REPO_URL" >/dev/null

ok "Gitea SSH deploy-key authentication and repository read access work"
