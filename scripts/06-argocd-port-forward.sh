#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd kubectl
require_kubeconfig
require_env ARGOCD_NAMESPACE

log "Argo CD UI: https://127.0.0.1:8080"
exec kubectl -n "$ARGOCD_NAMESPACE" port-forward svc/argocd-server 8080:443
