#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

key="$PROJECT_ROOT/.secrets/gitea-argocd.pub"
[[ -s "$key" ]] || die "deploy key missing; run task gitea:keygen"
cat "$key"
