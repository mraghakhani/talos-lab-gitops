#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

# Connect Argo CD to Gitea and install the talos-lab root GitOps Application.
#
# Everything here is declarative kubectl: the repository registration is a
# repository-type Secret (the same object `argocd repo add` would create) and
# the project/root Application are rendered manifests. No port-forward or
# argocd CLI session is needed, so this works even where kubectl
# port-forward is unreliable.

need_cmd kubectl
require_kubeconfig
for var in ARGOCD_NAMESPACE GITOPS_REPO_URL; do
  require_env "$var"
done

key="$PROJECT_ROOT/.secrets/gitea-argocd"
known_hosts="$PROJECT_ROOT/config/gitea-known-hosts"

[[ -s "$key" ]] || die "deploy key missing; run task gitea:keygen first"
[[ -s "$known_hosts" ]] \
  || die "Gitea known-hosts file missing; run task gitea:known-hosts:update"

"$PROJECT_ROOT/scripts/02-render.sh"

log "waiting for Argo CD server"
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=5m

log "registering GitOps repository"
kubectl -n "$ARGOCD_NAMESPACE" create secret generic talos-gitops-repo \
  --from-literal=type=git \
  --from-literal=url="$GITOPS_REPO_URL" \
  --from-file=sshPrivateKey="$key" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "$ARGOCD_NAMESPACE" label secret talos-gitops-repo \
  argocd.argoproj.io/secret-type=repository --overwrite >/dev/null

log "applying Argo CD platform project"
kubectl apply -f "$PROJECT_ROOT/.rendered/project.yaml"

log "applying root GitOps application"
kubectl apply -f "$PROJECT_ROOT/.rendered/root-application.yaml"

ok "Argo CD is connected to Gitea and the talos-lab root Application is installed"