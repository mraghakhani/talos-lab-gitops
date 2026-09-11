#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=./scripts/lib.sh
source "$(dirname "$0")/lib.sh"

need_cmd bash

log "Bash syntax"
while IFS= read -r -d '' file; do
  bash -n "$file"
done < <(find "$PROJECT_ROOT/scripts" -type f -name '*.sh' -print0)

if command -v shellcheck >/dev/null 2>&1; then
  log "ShellCheck"
  shellcheck -x "$PROJECT_ROOT"/scripts/*.sh
else
  note "shellcheck not installed; skipped"
fi

if command -v yamllint >/dev/null 2>&1; then
  log "YAML lint"
  yamllint -c "$PROJECT_ROOT/.yamllint.yml" \
    "$PROJECT_ROOT/Taskfile.yml" \
    "$PROJECT_ROOT/config/versions.yaml" \
    "$PROJECT_ROOT/clusters/talos-lab/kustomization.yaml" \
    "$PROJECT_ROOT/clusters/talos-lab/namespaces.yaml"
else
  note "yamllint not installed; skipped"
fi

if command -v kubectl >/dev/null 2>&1; then
  log "Kustomize render"
  kubectl kustomize "$PROJECT_ROOT/clusters/talos-lab" >/dev/null
fi

ok "repository validation passed"
