#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

for cmd in go-task kubectl helm argocd curl envsubst ssh-keygen ssh-keyscan; do
  need_cmd "$cmd"
done

[[ -f "$PROJECT_ROOT/.env" ]] || die "copy .env.example to .env and edit it first"

for var in \
  GITEA_HTTP_URL GITEA_SSH_HOST GITEA_SSH_PORT GITOPS_REPO_URL GITOPS_BRANCH \
  ARGOCD_NAMESPACE ARGOCD_DOMAIN ARGOCD_CHART_VERSION HOST_HTTP_PROXY \
  CLUSTER_HTTP_PROXY CLUSTER_NO_PROXY; do
  require_env "$var"
done

require_kubeconfig

case "$GITOPS_REPO_URL" in
*YOUR_GITEA_USER*) die "replace YOUR_GITEA_USER in .env" ;;
esac

ok "workstation and repository configuration look usable"
