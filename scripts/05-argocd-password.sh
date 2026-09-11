#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd argocd
require_kubeconfig
require_env ARGOCD_NAMESPACE
argocd admin initial-password -n "$ARGOCD_NAMESPACE"
