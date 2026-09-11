#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd argocd
need_cmd kubectl
need_cmd curl
need_cmd ssh-keyscan
need_cmd base64

require_kubeconfig
for var in ARGOCD_NAMESPACE GITEA_SSH_HOST GITEA_SSH_PORT GITOPS_REPO_URL; do
  require_env "$var"
done

key="$PROJECT_ROOT/.secrets/gitea-argocd"
[[ -s "$key" ]] || die "deploy key missing; run task gitea:keygen first"

"$PROJECT_ROOT/scripts/02-render.sh"

log "waiting for Argo CD server"
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=5m

log "starting temporary Argo CD port-forward"
pf_log="$(mktemp)"
known_hosts="$(mktemp)"
kubectl -n "$ARGOCD_NAMESPACE" port-forward svc/argocd-server 18080:443 >"$pf_log" 2>&1 &
pf_pid=$!

cleanup() {
  kill "$pf_pid" >/dev/null 2>&1 || true
  wait "$pf_pid" 2>/dev/null || true
  rm -f "$pf_log" "$known_hosts"
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 30); do
  if curl -kfsS --max-time 2 https://127.0.0.1:18080/healthz >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [[ "$ready" -ne 1 ]]; then
  cat "$pf_log" >&2 || true
  die "Argo CD port-forward did not become ready"
fi

password="$(
  kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d
)"
[[ -n "$password" ]] || die "unable to read Argo CD initial admin password"

log "logging in to local Argo CD API"
argocd login 127.0.0.1:18080 \
  --username admin \
  --password "$password" \
  --insecure \
  --grpc-web >/dev/null

log "registering Gitea SSH host key"
ssh-keyscan -p "$GITEA_SSH_PORT" "$GITEA_SSH_HOST" >"$known_hosts" 2>/dev/null
[[ -s "$known_hosts" ]] || die "unable to scan Gitea SSH host key"

argocd cert add-ssh \
  --server 127.0.0.1:18080 \
  --insecure \
  --grpc-web \
  --batch \
  --upsert <"$known_hosts"

log "registering GitOps repository"
argocd repo add "$GITOPS_REPO_URL" \
  --server 127.0.0.1:18080 \
  --insecure \
  --grpc-web \
  --ssh-private-key-path "$key" \
  --upsert

log "applying Argo CD platform project"
kubectl apply -f "$PROJECT_ROOT/.rendered/project.yaml"

log "applying root GitOps application"
kubectl apply -f "$PROJECT_ROOT/.rendered/root-application.yaml"

ok "Argo CD is connected to Gitea and the talos-lab root Application is installed"
