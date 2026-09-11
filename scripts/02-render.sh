#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd envsubst

for var in \
  ARGOCD_NAMESPACE ARGOCD_DOMAIN CLUSTER_HTTP_PROXY CLUSTER_NO_PROXY \
  GITOPS_REPO_URL GITOPS_BRANCH
do
  require_env "$var"
done

out="$PROJECT_ROOT/.rendered"
mkdir -p "$out"

envsubst <"$PROJECT_ROOT/platform/argocd/values.yaml.tmpl" >"$out/argocd-values.yaml"
envsubst <"$PROJECT_ROOT/bootstrap/templates/project.yaml.tmpl" >"$out/project.yaml"
envsubst <"$PROJECT_ROOT/bootstrap/templates/root-application.yaml.tmpl" >"$out/root-application.yaml"

ok "rendered bootstrap files under .rendered/"
