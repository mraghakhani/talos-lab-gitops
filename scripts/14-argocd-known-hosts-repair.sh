#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd kubectl
require_kubeconfig
require_env ARGOCD_NAMESPACE

warn "removing the imperatively-mutated SSH known-hosts ConfigMap so Helm can recreate and own it"
kubectl -n "$ARGOCD_NAMESPACE" \
  delete configmap argocd-ssh-known-hosts-cm \
  --ignore-not-found

ok "ConfigMap removed; run task argocd:install now"
