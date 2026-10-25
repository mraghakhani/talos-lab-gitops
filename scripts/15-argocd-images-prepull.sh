#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

# Pre-pull the pinned Argo CD chart images into the CRI namespace on every
# cluster node, so argocd:install does not stall on slow registry access.
#
# The image list is discovered from the same chart version and rendered
# values that argocd:install deploys, so it can never drift from the install.
# Node IPs come from the live cluster (InternalIP), so this repository does
# not duplicate the node inventory owned by talos-lab.

need_cmd helm
need_cmd kubectl
need_cmd talosctl
need_cmd timeout
need_cmd yq
need_cmd sort
require_kubeconfig
require_env ARGOCD_NAMESPACE
require_env ARGOCD_CHART_VERSION
require_env HOST_HTTP_PROXY
require_env TALOSCONFIG

PULL_RETRIES="${ARGOCD_IMAGE_PULL_RETRIES:-4}"
PULL_TIMEOUT="${ARGOCD_IMAGE_PULL_TIMEOUT:-180s}"

[[ -s "$TALOSCONFIG" ]] || die "talosconfig does not exist or is empty: $TALOSCONFIG"

"$PROJECT_ROOT/scripts/02-render.sh"

log "adding/updating official Argo Helm repository"
HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
  helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null

HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
  helm repo update argo >/dev/null

log "discovering images from argo-cd chart $ARGOCD_CHART_VERSION"
mapfile -t images < <(
  HTTP_PROXY="$HOST_HTTP_PROXY" HTTPS_PROXY="$HOST_HTTP_PROXY" \
  NO_PROXY="localhost,127.0.0.1,192.168.231.0/24" \
    helm template argocd argo/argo-cd \
      --namespace "$ARGOCD_NAMESPACE" \
      --version "$ARGOCD_CHART_VERSION" \
      --values "$PROJECT_ROOT/.rendered/argocd-values.yaml" \
    | yq -r -N '.. | .image? | select(. != null)' | sort -u
)
((${#images[@]} > 0)) || die "no container images found in rendered Argo CD chart"

node_ips="$(kubectl get nodes \
  -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')"
read -ra nodes <<<"$node_ips"
((${#nodes[@]} > 0)) || die "no node InternalIPs found via kubectl"

printf 'Argo CD images (%d):\n' "${#images[@]}"
printf '  %s\n' "${images[@]}"
printf 'Nodes (%d):\n' "${#nodes[@]}"
printf '  %s\n' "${nodes[@]}"

pull_image() {
  local ip="$1"
  local image="$2"
  local attempt delay

  for ((attempt = 1; attempt <= PULL_RETRIES; attempt++)); do
    log "$ip [cri] pull $image (attempt $attempt/$PULL_RETRIES)"
    if timeout "$PULL_TIMEOUT" talosctl \
      --talosconfig "$TALOSCONFIG" \
      --endpoints "$ip" \
      --nodes "$ip" \
      image pull \
      --namespace cri \
      "$image"; then
      return 0
    fi

    if ((attempt < PULL_RETRIES)); then
      delay=$((attempt * 3))
      warn "$ip failed to pull $image; retrying in ${delay}s"
      sleep "$delay"
    fi
  done

  die "$ip failed to pull $image after $PULL_RETRIES attempts"
}

for ip in "${nodes[@]}"; do
  for image in "${images[@]}"; do
    pull_image "$ip" "$image"
  done
done

ok "Argo CD chart images are pre-pulled on all nodes"