#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd ssh-keygen

dir="$PROJECT_ROOT/.secrets"
key="$dir/gitea-argocd"

mkdir -p "$dir"
chmod 700 "$dir"

if [[ -f "$key" ]]; then
  note "deploy key already exists: $key"
else
  ssh-keygen -t ed25519 -N "" -C "argocd@talos-lab" -f "$key"
  chmod 600 "$key"
  chmod 644 "$key.pub"
fi

echo
log "Add this PUBLIC key to the talos-gitops Gitea repo as a READ-ONLY deploy key:"
cat "$key.pub"
