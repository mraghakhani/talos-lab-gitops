#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd helm
need_cmd kubectl
require_kubeconfig
require_env ARGOCD_NAMESPACE
require_env ARGOCD_CHART_VERSION
require_env HOST_HTTP_PROXY

"$PROJECT_ROOT/scripts/02-render.sh"

log "adding/updating official Argo Helm repository"
HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
  helm repo add argo https://argoproj.github.io/argo-helm --force-update

HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
  helm repo update argo

log "creating Argo CD namespace"
kubectl create namespace "$ARGOCD_NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

log "enforcing restricted Pod Security on $ARGOCD_NAMESPACE"
kubectl label namespace "$ARGOCD_NAMESPACE" \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted \
  --overwrite

log "installing Argo CD chart $ARGOCD_CHART_VERSION"
HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
  helm upgrade --install argocd argo/argo-cd \
    --namespace "$ARGOCD_NAMESPACE" \
    --version "$ARGOCD_CHART_VERSION" \
    --values "$PROJECT_ROOT/.rendered/argocd-values.yaml" \
    --wait \
    --timeout 10m

ok "Argo CD Helm release installed"
