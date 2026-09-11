#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd kubectl
require_kubeconfig
require_env ARGOCD_NAMESPACE

log "Argo CD pods"
kubectl -n "$ARGOCD_NAMESPACE" get pods -o wide

echo
log "Argo CD services"
kubectl -n "$ARGOCD_NAMESPACE" get svc

echo
log "Argo CD applications"
kubectl -n "$ARGOCD_NAMESPACE" get applications.argoproj.io 2>/dev/null || true
