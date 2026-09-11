#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd kubectl
require_kubeconfig
require_env ARGOCD_NAMESPACE

kubectl -n "$ARGOCD_NAMESPACE" get application talos-lab \
  -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision'
